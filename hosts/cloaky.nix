{ pkgs, ... }:
{

  nix = {
    enable = true;
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
      !include ./extra.conf
    '';
  };
  programs.home-manager.enable = true;
  home.packages = with pkgs; [
    cloudflared
    nvd
    deno
    ollama
    go
  ];
  home.shellAliases = {
    cat = "bat";
  };
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
  home.sessionVariables = {
    OLLAMA_HOST = "http://bigbox1.lab.internal:11434";
  };
}
