# frozen_string_literal: true

# Bootstrap for the niri appmatcher backend.
#
# fusuma-plugin-appmatcher hardcodes its backend list in
# `fusuma/plugin/appmatcher.rb` and offers no registry for third-party
# backends, so our Niri backend must be required explicitly. Fusuma only
# auto-requires `fusuma/plugin/<base-namespace>/*.rb` (detectors, inputs,
# buffers, ...) from `fusuma-plugin-*` gems on the load path; it never scans
# the `appmatcher/` backend directory. This file therefore lives in the
# `detectors` namespace purely so Fusuma auto-loads it at boot — it registers
# no detector, it just pulls in the backend and the `backend_klass` patch.
require "fusuma/plugin/appmatcher"
require "fusuma/plugin/appmatcher/niri"
require "fusuma/plugin/appmatcher/niri_backend_patch"
