{ pkgs, lib }:

{
  # YAML validation helper — validates YAML syntax at build time
  validateYaml = name: content:
    let
      validated = pkgs.runCommand "${name}-validated" { } ''
        ${pkgs.yq}/bin/yq eval -e '.' > /dev/null <<'EOF'
        ${content}
        EOF
        echo "${content}" > $out
      '';
    in
    validated;
}
