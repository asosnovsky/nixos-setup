{ ... }:
{
  skyg.nixos.common.networking.nfsServer.enable = true;
  services.nfs.server = {
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';
    exports = ''
      /mnt/Data/apps  10.0.0.0/16(rw,wdelay,insecure,no_root_squash,no_subtree_check,sec=sys,rw,insecure,no_root_squash,no_all_squash)
    '';
  };
}
