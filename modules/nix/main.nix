{ user
, systemStateVersion
}:
{ ... }:
{
  imports = [
    (import ./core.nix {
      user = user;
      systemStateVersion = systemStateVersion;
    })
  ];
}
