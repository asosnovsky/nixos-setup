# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "fusuma-plugin-niri-appmatcher"
  spec.version       = "0.1.0"
  spec.authors       = ["Ari Sosnovsky"]
  spec.email         = ["ari@sosnovsky.ca"]
  spec.summary       = "Niri appmatcher plugin for Fusuma"
  spec.description   = "Provides per-application gesture rules for the niri Wayland compositor by querying the focused window via niri IPC."
  spec.homepage      = "https://github.com/skykanin/nixos-setup"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "fusuma", "~> 3.0"
end
