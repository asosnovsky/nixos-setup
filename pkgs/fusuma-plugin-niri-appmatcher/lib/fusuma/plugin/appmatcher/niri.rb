# frozen_string_literal: true

require "json"
require "open3"
require "socket"
require "fusuma/plugin/appmatcher/user_switcher"
require "fusuma/multi_logger"
require "fusuma/custom_process"

module Fusuma
  module Plugin
    module Appmatcher
      # Search Active Window's Name for niri (scrollable-tiling Wayland compositor)
      class Niri
        include UserSwitcher

        attr_reader :reader, :writer

        # @return [Boolean]
        def self.available?
          return true if ENV["NIRI_SOCKET"]

          ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |dir|
            path = File.join(dir, "niri")
            File.executable?(path) && !File.directory?(path)
          end
        end

        def initialize
          @reader, @writer = IO.pipe
        end

        # fork process and watch signal
        # @return [Integer] Process id
        def watch_start
          as_user(proctitle: self.class.name.underscore) do |_user|
            @reader.close
            register_on_application_changed(Matcher.new)
          end
        end

        private

        def register_on_application_changed(matcher)
          @writer.puts(matcher.active_application || "NOT FOUND")

          matcher.on_active_application_changed do |name|
            notify(name)
          end
        end

        def notify(name)
          @writer.puts(name)
        rescue Errno::EPIPE
          exit 0
        rescue => e
          MultiLogger.error e.message
          exit 1
        end

        # Look up application name using the niri IPC socket
        class Matcher
          # @return [Array<String>]
          def running_applications
            request("Windows")["Ok"]["Windows"]
              .map { |w| w["app_id"] }
              .compact
              .uniq
          rescue => e
            MultiLogger.error "Failed to get running applications: #{e.message}"
            []
          end

          # @return [String, nil]
          def active_application
            request("FocusedWindow")["Ok"]["FocusedWindow"]&.dig("app_id")
          rescue => e
            MultiLogger.error "Failed to get active application: #{e.message}"
            nil
          end

          # Subscribe to niri's event stream and yield the app_id on focus change
          def on_active_application_changed
            unix_socket_request("EventStream") do |socket|
              # The first line of an EventStream reply is the Ok confirmation;
              # subsequent lines are JSON events.
              socket.each_line do |line|
                event = JSON.parse(line)
                changed = event["WindowFocusChanged"] ||
                          event.dig("WindowsChanged", "windows") &&
                            event["WindowsChanged"]["windows"].find { |w| w["is_focused"] }

                app_id =
                  case changed
                  when Hash then changed["app_id"]
                  when NilClass then nil
                  else changed && active_application
                  end

                # WindowFocusChanged carries { id: ... } or null; on id-only
                # events re-query the focused window for its app_id.
                app_id ||= active_application if event["WindowFocusChanged"]

                yield(app_id || "NOT FOUND") if app_id || event["WindowFocusChanged"]
              rescue JSON::ParserError
                next
              end
            end
          rescue => e
            MultiLogger.error "Niri subscription error: #{e.message}"
            sleep 1
            retry
          end

          private

          # @return [String]
          def socket_path
            ENV["NIRI_SOCKET"] || raise("NIRI_SOCKET is not set")
          end

          # Send a single request and return the parsed reply (one line of JSON).
          def request(action)
            unix_socket_request(action) { |s| JSON.parse(s.gets) }
          end

          def unix_socket_request(action)
            UNIXSocket.open(socket_path) do |socket|
              socket.puts(JSON.generate(action))
              yield socket
            end
          end
        end
      end
    end
  end
end
