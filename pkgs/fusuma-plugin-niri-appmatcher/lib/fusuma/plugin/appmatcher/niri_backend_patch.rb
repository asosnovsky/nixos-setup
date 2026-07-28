# frozen_string_literal: true

# Registers the niri backend for fusuma-plugin-appmatcher.
#
# Upstream `Fusuma::Plugin::Appmatcher.backend_klass` selects a backend via a
# hardcoded case on XDG_SESSION_TYPE / XDG_CURRENT_DESKTOP and knows nothing
# about niri. We prepend a module that returns our Niri backend whenever it is
# available (i.e. NIRI_SOCKET is set), and otherwise defer to upstream.
#
# This file lives in a nested path on purpose: Fusuma's plugin manager
# auto-requires `fusuma/plugin/**/*.rb` from fusuma-plugin-* gems but
# explicitly excludes top-level files (fusuma/plugin/<name>.rb).
require_relative "niri"

module Fusuma
  module Plugin
    module Appmatcher
      module NiriBackendSelection
        def backend_klass
          return Niri if Niri.available?

          super
        end
      end

      singleton_class.prepend(NiriBackendSelection)
    end
  end
end
