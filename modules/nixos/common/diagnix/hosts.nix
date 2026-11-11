# Lab hosts diagnix lives on, shared by the host module and nbot's agent system.
# hostKey is the host's ssh_host_ed25519 public key (from secrets.nix);
# null means the agent saves it on first connect.
{
  # LAN addresses of the hosts that run nbot. The key only works from these.
  nbotHosts = [ "10.0.10.11" "10.0.10.13" ]; # hl-fwdesk, hl-fws1
  lanSubnet = "10.0.0.0/16";

  # The nbot client public key. Private half (base64) is DIAGNIX_KEY in the
  # nbot-goose secret, sent to containers via agent_env on fwdesk.
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKsgkysVa3BiJQkUjiyESwjoi9ZMmUiWEB66JlbgIrO nbot-diagnix";

  hosts = {
    hl-bigbox1 = { address = "bigbox1.lab.internal"; hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFl5xiH4aFlmDWdoU+KmERLYOeOQK2aKP7jenY2G3rFb"; };
    hl-bigbox2 = { address = "bigbox2.lab.internal"; hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL6l6VqQ23PkGkWVABBoLp1KA6PzkX5oKTy5RBHbQXet"; };
    hl-fwdesk = { address = "fwdesk.lab.internal"; hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHbBcdMpNPaELUzHRIoRkTUQde+mBQ87Ra2R+974FuUy"; };
    hl-fws1 = { address = "fws1.lab.internal"; hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM6r0AIJyTlE+U6K97GijzAP4jNaAueVlwXbeMpEMcpe"; };
    hl-minipc1 = { address = "minipc1.lab.internal"; hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP42vtV9Qo7q5F9M/rCGD/TIZG3d0mm1uP6lMvy3zF/a"; };
    hl-minipc2 = { address = "minipc2.lab.internal"; hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDqi2WT0pa8m+kZNN2Rrg1F01zwTvkCwD3wjSOBNvSjz"; };
    hl-minipc3 = { address = "minipc3.lab.internal"; hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbvoe/UvhpRSWVXMCyj/qzuR7WnJdNF7CYRmmJE3yYu"; };
    hl-pi1 = { address = "pi1.lab.internal"; hostKey = null; };
    hl-pi2 = { address = "pi2.lab.internal"; hostKey = null; };
    hl-terra1 = { address = "terra1.lab.internal"; hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHBKI8gqd7DDubShle4D3JGq61BP1NBKCZ81V3C9uyym"; };
  };
}
