{ config
, lib
, skygUtils
, ...
}:
let
  cfg = config.skyg.configLinks;
  userName = config.skyg.user.name;
  rootHome = config.users.users.root.home;

  # Store copy of a link's source. Eval fails if the configs/ file is missing.
  bakedOf = name: link:
    if link.storePath != null then
      "${link.storePath}"
    else
      "${builtins.path {
        path = config.skyg.configsDir + "/${link.source}";
        name = "skyg-cfg-${name}";
      }}";

  # Link for the main user: the live checkout when allowed and present,
  # else the store copy.
  userLink = name: link:
    let
      baked = bakedOf name link;
      target = "$HOME/${link.target}";
    in
    if cfg.live && !link.baked && link.source != null then ''
      src="${cfg.liveRoot}/${link.source}"
      [[ -e "$src" ]] || src="${baked}"
      ${skygUtils.makeLinkScript { source = "$src"; inherit target; }}
    '' else
      skygUtils.makeLinkScript { source = baked; inherit target; };

  # Root always gets the store copy.
  rootLink = name: link: skygUtils.makeLinkScript {
    source = bakedOf name link;
    target = "${rootHome}/${link.target}";
  };

  rootLinks = lib.filterAttrs (_: link: link.root) cfg.links;

  linkType = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "shared/zellij/config.kdl";
        description = "File or dir to link, as a path under `configs/`.";
      };
      storePath = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Nix-built file or dir to link instead of a `configs/` path.";
      };
      target = lib.mkOption {
        type = lib.types.str;
        example = ".config/zellij/config.kdl";
        description = "Where the link goes, as a path under the home dir.";
      };
      baked = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Always link the read-only store copy, even on hosts with
          `skyg.configLinks.live`. Use for files apps must not rewrite.
        '';
      };
      root = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Also link for root (always the store copy).";
      };
    };
  };
in
{
  options.skyg.configLinks = {
    live = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Link to the live checkout (`liveRoot`) so edits apply without a
        rebuild. Falls back to the store copy when the checkout or file is
        missing. Off by default: servers have no checkout.
      '';
    };
    liveRoot = lib.mkOption {
      type = lib.types.str;
      default = "/home/${userName}/nixos-setup/configs";
      description = "The `configs/` dir of the live checkout.";
    };
    links = lib.mkOption {
      type = lib.types.attrsOf linkType;
      default = { };
      description = ''
        Files or dirs from `configs/` to symlink into the home dir of
        `skyg.user.name` (and of root, for links with `root = true`).
      '';
    };
  };

  config = lib.mkIf (cfg.links != { }) {
    assertions = lib.mapAttrsToList
      (name: link: {
        assertion = (link.source == null) != (link.storePath == null);
        message = "skyg.configLinks.links.${name}: set exactly one of `source` or `storePath`";
      })
      cfg.links;

    # Runs at login and on every switch, as each logged-in normal user.
    system.userActivationScripts.skygConfigLinks.text = ''
      if [[ "$(id -un)" == "${userName}" ]]; then
        ${lib.concatStrings (lib.mapAttrsToList userLink cfg.links)}
      fi
    '';

    # The user activation service skips system users, so root is done here.
    system.activationScripts.skygRootConfigLinks = lib.mkIf (rootLinks != { }) {
      text = lib.concatStrings (lib.mapAttrsToList rootLink rootLinks);
    };
  };
}
