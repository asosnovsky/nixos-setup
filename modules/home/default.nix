{ stateVersion }:
let
  makeCommonGitConfigs = (import ./git.nix).makeCommonGitConfigs;
  programsModule = (import ./programs.nix);
  servicesModule = (import ./services.nix);
  homeModule = {
    stateVersion = stateVersion;
    shellAliases = {
      cat = "bat";
    };
  };
in
{
  makeRootUser = { hostName }: { pkgs, ... }: {
    home = homeModule;
    programs = (programsModule { pkgs = pkgs; }) // {
      git = (makeCommonGitConfigs {
        userName = "root";
        userEmail = "root@${hostName}";
        extraGitConfigs = [ ];
      });
    };
    services = servicesModule { pkgs = pkgs; };
  };

  makeCommonUser =
    { enableDevelopmentKit ? false
    , fullName
    , email
    , extraGitConfigs ? [ ]
    , name
    , ...
    }: { pkgs, ... }: {
      home = homeModule // {
        username = name;
        homeDirectory = "/home/${name}";
        packages = with pkgs;
          [ jq nixpkgs-fmt ipfetch nixd ]
            ++ (if enableDevelopmentKit then [
            devenv
            devbox
            terraform
            kubectl

            # socials
            slack
            zoom-us
            betterdiscordctl
            discord
            signal-desktop
            whatsapp-for-linux
            caprine-bin # facebook messenger

            # development
            vscode

            # web
            brave

            # mail
            thunderbird

            # password
            bitwarden-desktop

            # documents
            onlyoffice-bin_latest

            # video
            vlc
            vlc-bittorrent

            # terminal
            alacritty
            alacritty-theme

          ] else
            [ ]);
      };
      programs = (programsModule { pkgs = pkgs; }) // {
        git = (makeCommonGitConfigs {
          userName = fullName;
          userEmail = email;
          extraGitConfigs = extraGitConfigs;
        });
      };
      services = servicesModule { pkgs = pkgs; };
    };
}
