{ lib
, rustPlatform
, fetchFromGitHub
}:

# Buzz CLI (`buzz`, crates/buzz-cli in block/buzz). Hermes's Buzz platform
# runs it, so a robot with a Buzz identity needs it. Upstream ships no binary.
# Pinned to the same tag as pkgs/buzz-desktop. The relay image tracks `main`,
# so bump both together if the CLI and relay stop agreeing.
#
# To bump: run ./update.sh [<version>] (sets the source hash, resets
# cargoHash), then build once and paste the cargoHash from the "got:" line.

rustPlatform.buildRustPackage rec {
  pname = "buzz-cli";
  version = "0.5.28";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    rev = "desktop-v${version}";
    hash = "sha256-NEsLQwcoQ2zTgznFgGFGNgYPnoclicNVycSEjl7I0Wo=";
  };

  # The workspace has git deps in [patch.crates-io]; cargoHash covers them.
  cargoHash = lib.fakeHash;

  # Only this crate; the workspace has 30+ others (relay, db, ...).
  cargoBuildFlags = [ "-p" "buzz-cli" ];
  doCheck = false;

  meta = {
    description = "Buzz CLI, the agent-facing command line for a Buzz relay";
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    mainProgram = "buzz";
  };
}
