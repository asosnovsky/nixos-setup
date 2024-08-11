{ stateVersion }:
let
  makeCommonGitConfigs = (import ./git).makeCommonGitConfigs;
  programsModule = (import ./programs);
  servicesModule = (import ./services);
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
    { enableDevelopmentKit
    , fullName
    , email
    , extraGitConfigs ? [ ]
    , ...
    }: { pkgs, ... }: {
      home = homeModule // {
        packages = with pkgs;
          [ jq nixpkgs-fmt ipfetch nixd ]
            ++ (if enableDevelopmentKit then [
            rye
            devenv
            uv
            devbox
            terraform
            kubectl
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
