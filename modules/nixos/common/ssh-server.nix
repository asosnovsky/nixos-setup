{ config, lib, ... }:
with lib;

let
  cfg = config.skyg.ssh-server;
in
{
  options = {
    skyg.ssh-server = {
      enabled = mkEnableOption
        "enable ssh server";
      masterPubKey = mkOption {
        type = types.str;
        default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuatskL9qXvgvS3E8zRwosFnpcN0f8PkKl8syAvpn297V2iPk6mi8yK3EE7xPpxaKKlwUuBHDj3BNUCoLgdRFKUgroRDzr3BMm+gZTHy6CuEZBY9zBRTmH+aOV6FZ96QPW4zba0BW5YPkPNy/FhYibjpXyZ3nX4/LWSbPKQJ7wTnUJZgq4VFmevBOttvhzUJUgTziMFsGXn6I38fAi6LI8qwI+zOOdsNjtKgr/TIlO/7VqcH7GYnQEwlthl577sDd1V6+XWz649qoiBYyq0Ahm09dwYx2iGQwLo8IYFbSy4aJRK/PI0+ytnPBoF5QCl+ILb5E8uV3e6Wb9WpXl9Hv2iLx91/9iq5hykHPnfVtkq3MK0C2vqkvX1qFOIkKM7vmxvXGbaDZDGK3G+/zkQ7GUw8ydbl9wGwE9cKbm9miqs4w2Ry/+3IZasE6G2TI97bSzSYInQd2RwoglqBOaJojbUqgI9wvNdKxGhADNFbZah2+s6SSe1ByQRN3b9wtmqu0= ari@shared";
      };
    };
  };
  config = mkIf cfg.enabled {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
      settings.PermitRootLogin = "yes";
    };
    users.users.${config.skyg.user.name}.openssh.authorizedKeys.keys = [
      cfg.masterPubKey
    ];
    users.users.root.openssh.authorizedKeys.keys = [
      cfg.masterPubKey
    ];
  };
}

