# -------------------------------------------------------------------
# TEMPLATE — hardware-configuration.nix for Nitro 5
# -------------------------------------------------------------------
# This is a PLACEHOLDER. On first boot, the setup.sh bootstrap script
# will auto-generate this file using:
#
#   nixos-generate-config --show-hardware-config > hardware-configuration.nix
#
# You can also generate it manually on the Nitro 5:
#   sudo nixos-generate-config
#   # Then copy /etc/nixos/hardware-configuration.nix here
#
# DO NOT use this template as-is — it will not boot!
# -------------------------------------------------------------------
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # TODO: These will be auto-populated by nixos-generate-config
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # TODO: Replace with your actual disk UUID from nixos-generate-config
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/XXXX-XXXX";
    fsType = "vfat";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # AMD CPU microcode updates
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
