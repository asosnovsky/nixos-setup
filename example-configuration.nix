{ ... }:
{
  imports =
    [ 
      (import ./main.nix {
        hostName = "framework1";
        user = {
          name = "ari";
        };
      })
    ];
}
