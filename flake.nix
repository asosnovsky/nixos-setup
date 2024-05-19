{
  inputs = {
    modules = {
      url = "path:modules/";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
  };

  outputs = { self, modules, nixos-hardware }:
    let
      user = {
        name = "ari";
        fullName = "Ari Sosnovsky";
        email = "ariel@sosnovsky.ca";
      };
      homeMangerVersion = "24.05";
    in
    {
      nixosConfigurations."fwbook" = modules.lib.makeNixOsModule {
        system = "x86_64-linux";
        user = user;
        systemStateVersion = "23.11";
        hostName = "fwbook";
        home-manager = {
          enable = true;
          mode = "nixos";
          version = homeMangerVersion;
        };
        desktop = {
          enable = true;
          user = user;
          enableKDE = true;
          enableHypr = true;
          enableX11 = true;
          enableWine = true;
        };
        os = {
          enable = true;
          firewall = { enable = false; };
          enableFonts = true;
          enableNetowrking = true;
          enableSSH = false;
          hardware = { enable = true; };
        };
        configuration = { ... }: {
          imports = [ nixos-hardware.nixosModules.framework-13-7040-amd ];
        };
      };
    };
}
