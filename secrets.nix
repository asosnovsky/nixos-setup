let
  ari = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDdRSMk+ktnGcaa9KtGytKkQJ7zyHo/D2uj67snR9M2C ari@fwbook";
  minipc1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP42vtV9Qo7q5F9M/rCGD/TIZG3d0mm1uP6lMvy3zF/a root@nixos";
  minipc2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqi2WT0pa8m+kZNN2Rrg1F01zwTvkCwD3wjSOBNvSjz root@nixos";
  minipc3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbvoe/UvhpRSWVXMCyj/qzuR7WnJdNF7CYRmmJE3yYu root@minisf1";
  terra1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHBKI8gqd7DDubShle4D3JGq61BP1NBKCZ81V3C9uyym root@nixos";
  fwdesk = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHbBcdMpNPaELUzHRIoRkTUQde+mBQ87Ra2R+974FuUy root@hl-fwdesk";
  bigbox1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFl5xiH4aFlmDWdoU+KmERLYOeOQK2aKP7jenY2G3rFb root@nixos";
in
{
  "secrets/dns-addresses.conf.age".publicKeys = [
    ari
    minipc1
    minipc2
    minipc3
    terra1
    fwdesk
  ];

  # Decrypted at deploy time by the user running `skyg openwrt`
  "secrets/glmain.json.age".publicKeys = [ ari ];

  # Hermes envs
  "secrets/hermes-env.age".publicKeys = [ ari fwdesk ];

  "secrets/iu-project.age".publicKeys = [ ari minipc1 ];

  # Buzz stack env (minipc1)
  "secrets/buzz-env.age".publicKeys = [ ari minipc1 ];

  # Cloudflare DNS API token for ACME DNS-01 (skyg.server.acme)
  "secrets/cloudflare-dns.age".publicKeys = [ ari minipc1 ];

  # stack compose definition — minipc2
  "secrets/stack1.age".publicKeys = [ ari minipc2 ];
  "secrets/stack2.age".publicKeys = [ ari minipc2 ];

  # portainer agent envs
  "secrets/portainer-agent-bigbox1.age".publicKeys = [ ari bigbox1 ];
  "secrets/portainer-agent-minipc1.age".publicKeys = [ ari minipc1 ];
  "secrets/lab-ca-key.age".publicKeys = [ ari ];
  "secrets/buzz-tls-key.age".publicKeys = [ ari minipc1 ];
  "secrets/portainer-tls-key.age".publicKeys = [ ari minipc2 ];
}
