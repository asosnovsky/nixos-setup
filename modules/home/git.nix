let
  gitconfigs =
    (builtins.filterSource (path: type: type != "directory") ./gitconfigs);
  gitconfigFiles = builtins.attrNames (builtins.readDir gitconfigs);
  makeCommonGitConfigs =
    { userName
    , userEmail
    , extraGitConfigs ? [ ]
    }: {
      delta = {
        enable = true;
        enableGitIntegration = true;
      };
      git = {
        enable = true;
        settings = {
          user = {
            name = userName;
            email = userEmail;
          };
          color = { ui = "auto"; };
          push = {
            default = "upstream";
            autoSetupRemote = true;
          };
          init = { defaultBranch = "main"; };
        };
        includes =
          (builtins.map (f: { path = gitconfigs + "/" + f; }) gitconfigFiles)
          ++ extraGitConfigs;
      };
    };
in
{
  makeCommonGitConfigs = makeCommonGitConfigs;
}
