let
  gitconfigs =
    (builtins.filterSource (path: type: type != "directory") ./gitconfigs);
  gitconfigFiles = builtins.attrNames (builtins.readDir gitconfigs);
  makeCommonGitConfigs =
    { userName
    , userEmail
    , extraGitConfigs ? [ ]
    }: {
      enable = true;
      userName = userName;
      userEmail = userEmail;
      delta = { enable = true; };
      extraConfig = {
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
in
{
  makeCommonGitConfigs = makeCommonGitConfigs;
}
