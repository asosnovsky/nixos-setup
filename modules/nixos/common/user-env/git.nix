{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.skyg.user;

  # Git name and email, included by configs/shared/git/config.
  gitIdentity = pkgs.writeText "git-identity" (lib.generators.toGitINI {
    user = {
      name = cfg.fullName;
      email = cfg.email;
    };
  });
in
{
  config = lib.mkIf cfg.enable {
    # delta is the pager set in configs/shared/git/config.
    environment.systemPackages = [ pkgs.delta ];

    # Identity is here and in ~/.config/git/identity (some gits skip
    # /etc/gitconfig); the rest is configs/shared/git/config.
    programs.git = {
      enable = true;
      config = {
        user = {
          name = cfg.fullName;
          email = cfg.email;
        };
      } // lib.optionalAttrs (cfg.extraGitConfigs != [ ]) {
        include.path = map (c: c.path) cfg.extraGitConfigs;
      };
    };

    skyg.configLinks.links = {
      git = {
        source = "shared/git/config";
        target = ".config/git/config";
        root = true;
      };
      git-identity = {
        storePath = gitIdentity;
        target = ".config/git/identity";
        root = true;
      };
    };
  };
}
