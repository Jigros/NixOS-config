{config, ...}: {
  # The old configuration used Realtek's r8168 driver because the in-tree
  # r8169 driver intermittently dropped carrier on this RTL8168/8111 adapter.
  boot.blacklistedKernelModules = ["r8169"];
  boot.kernelModules = ["r8168"];
  boot.extraModulePackages = [config.boot.kernelPackages.r8168];
}
