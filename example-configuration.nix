{ ... }:
{
  imports =
    [ 
      (import ./main.nix {
        hostName = "fw1";
        user = {
          name = "ari";
          fullName = "Ari Sosnovsky";
          email = "ariel@sosnovsky.ca";
        };
      })
    ];
}
