# This file is used to sign git commits using an SSH key.
{
  # Obviously, change this to your own SSH key.
  home.file.".ssh/allowed_signers".text = "* ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKxxyvIRjrf1VRsmh5V4lgPyIA2vJIpSWFV5BgFGs4Ll";

  programs.git.settings = {
    commit.gpgsign = true;
    gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    gpg.format = "ssh";
    user.signingkey = "~/.ssh/id_ed25519.pub";
  };
}
