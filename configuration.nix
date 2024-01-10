{ ... }:
{
  imports =
    [ 
      (import ./main.nix {
        systemStateVersion = "23.05";
        hostName = "framework1";
        user = {
          name = "ari";
        };
      })
    ];
}
