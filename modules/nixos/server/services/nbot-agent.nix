# nbot's agent system with our additions (gh, lab-ssh). Use it for nbot's `system`.
{ lib, nbot, ... }:

with lib;

let
  lab = import ../../common/diagnix/hosts.nix;

  # lab-ssh <host> [cmd...]: log in to a lab host as the read-only diagnix user.
  # The key comes base64-encoded in $DIAGNIX_KEY (agent_env, from the nbot-goose secret).
  labSsh = pkgs: pkgs.writeShellApplication {
    name = "lab-ssh";
    runtimeInputs = [ pkgs.openssh pkgs.coreutils ];
    text = ''
      host="''${1:-}"
      case "$host" in
      ${concatStrings (mapAttrsToList (name: h: ''
        ${name}|${removePrefix "hl-" name}) addr=${h.address}; check=${if h.hostKey == null then "accept-new" else "yes"} ;;
      '') lab.hosts)}
        *) echo "usage: lab-ssh <host> [command...]; hosts: ${concatStringsSep " " (attrNames lab.hosts)}" >&2; exit 2 ;;
      esac
      shift
      : "''${DIAGNIX_KEY:?DIAGNIX_KEY missing from agent_env}"
      key="$HOME/.ssh/diagnix"
      mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
      (umask 077; base64 -d <<<"$DIAGNIX_KEY" > "$key")
      exec ssh -i "$key" -o IdentitiesOnly=yes -o StrictHostKeyChecking="$check" "diagnix@$addr" "$@"
    '';
  };

  agentModule = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.gh (labSsh pkgs) ];
    programs.ssh.knownHosts = mapAttrs
      (name: h: { hostNames = [ name h.address ]; publicKey = h.hostKey; })
      (filterAttrs (_: h: h.hostKey != null) lab.hosts);
    # gh reads GH_TOKEN (from agent_env); git over HTTPS uses it through gh.
    programs.git = {
      enable = true;
      config.credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
    };
  };
in
{
  options.skyg.nixos.server.services.nbot-agent.system = mkOption {
    description = "nbot's agent system with gh and lab-ssh added. Use for nbot's `system`.";
    readOnly = true;
    type = types.package;
    default = (nbot.nixosConfigurations.agent.extendModules {
      modules = [ agentModule ];
    }).config.system.build.toplevel;
    # Keeps the manual from building it on every host.
    defaultText = literalExpression "nbot agent + gh + lab-ssh";
  };
}
