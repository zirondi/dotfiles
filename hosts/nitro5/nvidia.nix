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
  # Only "nvidia" here: with PRIME the module below adds the amdgpu device
  # itself (from amdgpuBusId). Listing "amdgpu" too gave X two amdgpu screens
  # and no NVIDIA at all (xrandr --listproviders had no NVIDIA-G0), so
  # nvidia-offload had nothing to offload to (seen on 2026-10-21).
  services.xserver.videoDrivers = [ "nvidia" ];

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

    # Saves video memory across suspend/resume
    powerManagement.enable = true;
    # No fine-grained power management: the driver reports "Runtime D3 status:
    # Not supported" on this platform (Ryzen 3000 Picasso + Turing; RTD3 needs
    # a newer CPU), so the card never sleeps. With the driver loaded it idles
    # in P8, which draws less than leaving it driverless.
    powerManagement.finegrained = false;
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
    mesa-demos # glxinfo: `nvidia-offload glxinfo -B` must name the NVIDIA card
  ];
}
