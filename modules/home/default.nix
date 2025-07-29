{ stateVersion }:
let
  makeCommonGitConfigs = (import ./git.nix).makeCommonGitConfigs;
  programsModule = (import ./programs.nix);
  servicesModule = (import ./services.nix);
  fontsModule = (import ./fonts.nix);
  homeModule = {
    stateVersion = stateVersion;
    shellAliases = {
      cat = "bat";
      ls = "eza";
      du = "dust";
      df = "duf";
      open = "xdg-open";
    };
  };
in
{
  makeRootUser = { hostName }: { pkgs, ... }: {
    home = homeModule // {
      packages = with pkgs; [
        jq
        kubectl
        kubectx
        htop
        btop
        duf
      ];
    };
    programs = (programsModule {
      pkgs = pkgs;
      user = {
        name = "root";
      };
    }) // {
      git = (makeCommonGitConfigs {
        userName = "root";
        userEmail = "root@${hostName}";
        extraGitConfigs = [ ];
      });
    };
    services = servicesModule { pkgs = pkgs; };
    fonts = fontsModule;
  };

  makeCommonUser =
    { fullName
    , email
    , extraGitConfigs ? [ ]
    , name
    , ...
    }@user: { pkgs, ... }: {
      fonts = fontsModule;
      gtk = (import ./gtk.nix { inherit pkgs; });
      home = homeModule // {
        username = name;
        homeDirectory = "/home/${name}";
        packages = with pkgs;
          [
            jq
            nixpkgs-fmt
            ipfetch
            nixd
            htop
            btop
            fastfetch
            kubectl
            kubectx
            terraform
            dust
          ];
      };
      programs = (programsModule {
        inherit pkgs user;
      }) // {
        git = (makeCommonGitConfigs {
          userName = fullName;
          userEmail = email;
          extraGitConfigs = extraGitConfigs;
        });
      };
      services = servicesModule { pkgs = pkgs; };
    };
}
