# -------------------------------------------------------------------
# systems/nixos/nitro5/nvidia.nix — NVIDIA GTX 1650 Configuration
# -------------------------------------------------------------------
# This module is ONLY imported on real hardware (nitro5 target).
# The VM target (nitro5-vm) skips this module entirely, so your
# config can be validated on a Mac without an actual GPU.
#
# TODO: Adjust settings based on your NVIDIA driver preferences.
#       If you use Wayland, see the Wayland section below.
# -------------------------------------------------------------------
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Both AMD and NVIDIA drivers loaded for hybrid graphics
  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];

  hardware.nvidia = {
    # Use the stable production branch (recommended for GTX 1650)
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Modesetting is required for most Wayland compositors and for
    # proper display initialization
    modesetting.enable = true;

    # Enable the open-source kernel module (available since driver 515)
    # The GTX 1650 (Turing) supports this. Set to false if you
    # experience issues.
    open = false; # TODO: Try true if you want the open-source module

    # Power management — useful for laptops
    powerManagement = {
      enable = true;
      # Fine-grained power management (Turing+ only)
      # Puts the GPU to sleep when not in use
      finegrained = true;
    };
  };

  # --- NVIDIA Optimus / PRIME ---
  # The Nitro 5 has hybrid graphics (AMD iGPU + NVIDIA dGPU)
  # TODO: Uncomment ONE of the following sections based on your preference

  # Option A: Offload mode (default, saves power)
  # The AMD iGPU handles the display, NVIDIA is used on-demand
  hardware.nvidia.prime = {
    offload = {
      enable = true;
      enableOffloadCmd = true; # Adds nvidia-offload command
    };
    # Tested on Acer Nitro 5: amdgpu on PCI:5:0:0, nvidia on PCI:1:0:0
    amdgpuBusId = "PCI:5:0:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  # Option B: Sync mode (always uses NVIDIA, more power, better perf)
  # hardware.nvidia.prime = {
  #   sync.enable = true;
  #   amdgpuBusId = "PCI:4:0:0";
  #   nvidiaBusId = "PCI:1:0:0";
  # };

  # --- OpenGL / Graphics ---
  hardware.graphics = {
    enable = true;
    # enable32Bit = true;  # For Steam / 32-bit games
  };

  # --- NVIDIA-specific packages ---
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia # GPU monitoring TUI
    # vulkan-tools         # For testing Vulkan support
    # glxinfo              # For testing OpenGL support
  ];
}
