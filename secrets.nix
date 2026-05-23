let
  ari = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDdRSMk+ktnGcaa9KtGytKkQJ7zyHo/D2uj67snR9M2C ari@fwbook";
  minipc1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP42vtV9Qo7q5F9M/rCGD/TIZG3d0mm1uP6lMvy3zF/a root@nixos";
  minipc2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqi2WT0pa8m+kZNN2Rrg1F01zwTvkCwD3wjSOBNvSjz root@nixos";
  minipc3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbvoe/UvhpRSWVXMCyj/qzuR7WnJdNF7CYRmmJE3yYu root@minisf1";
  terra1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHBKI8gqd7DDubShle4D3JGq61BP1NBKCZ81V3C9uyym root@nixos";
in
{
  "secrets/dns-addresses.conf.age".publicKeys = [
    ari
    minipc1
    minipc2
    minipc3
    terra1
  ];
}
