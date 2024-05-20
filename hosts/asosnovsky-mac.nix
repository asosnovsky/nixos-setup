{ user }:
{ pkgs, ... }:
let
  zshSumo = builtins.filterSource (p: t: true) ../configs/sumo;
  zshScripts = zshSumo + "/scripts";
  zshFunctions = zshSumo + "/functions.sh";
in
{
  home-manager.users.${user.name} = {
    home = {
      packages = with pkgs; [
        coreutils-prefixed
        awscli2
      ];
      shellAliases = {
        k = "kubectl";
        gradlew = "dev gradlew";
        psh = "source $HOME/git/github/psh/psh.sh";
        hcvault = "dev hcvault";
      };
      sessionVariables = {
        "DOCKER_DEFAULT_PLATFORM" = "linux/amd64";
        "SUMO_HOME" = "$HOME/git/sumo";
        "_JAVA_OPTIONS" = "-Djava.awt.headless=true";
        "LC_ALL" = "en_US.UTF-8";
        "JAVA_HOME" = "/Library/Java/JavaVirtualMachines/amazon-corretto-8.jdk/Contents/Home";
      };
      sessionPath = [
        "$HOME/.devcli/bin"
        "$HOME/.krew/bin"
        "$HOME/git/github/paas-infrastructure/bin"
        "$HOME/.krew/bin"
        zshScripts
      ];
    };
    programs.zsh.initExtra = ''
      			source ${zshFunctions}
      			source /dev/stdin <<< "$($HOME/.devcli/dev --init)"
      			complete -o default -F __start_kubectl k
      			source <(helm completion zsh)
      			complete -C '/opt/homebrew/bin/aws_completer' aws
      			source <(kubectl completion zsh)
      			test -f ~/.prada/artifactory.env && source ~/.prada/artifactory.env
      			ulimit -n $(sysctl -n kern.maxfilesperproc)
      		'';
  };
}
