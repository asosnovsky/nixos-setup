# nbot's agent system with our additions. Use it for nbot's `system`.
{ lib, nbot, ... }:

with lib;

let
  agentModule = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.gh ];
    # gh reads GH_TOKEN (from agent_env); git over HTTPS uses it through gh.
    programs.git = {
      enable = true;
      config.credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
    };
  };
in
{
  options.skyg.nixos.server.services.nbot-agent.system = mkOption {
    description = "nbot's agent system with gh added. Use for nbot's `system`.";
    readOnly = true;
    type = types.package;
    default = (nbot.nixosConfigurations.agent.extendModules {
      modules = [ agentModule ];
    }).config.system.build.toplevel;
    # Keeps the manual from building it on every host.
    defaultText = literalExpression "nbot agent + gh";
  };
}
