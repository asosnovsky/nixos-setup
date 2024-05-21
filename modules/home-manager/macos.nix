{ user }:
{ ... }: {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${user.name} = {
    home = {
      sessionVariables = { "DOCKER_DEFAULT_PLATFORM" = "linux/amd64"; };
    };
  };
}
