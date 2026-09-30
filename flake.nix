{
  description = "Zirondi's cross-platform system configurations";

  inputs = {
    # --- Core ---
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # --- macOS (nix-darwin) ---
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Home Manager ---
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Hardware quirks for specific devices ---
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Applications & Remote Tools ---
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nixos-hardware, disko, sops-nix, vscode-server, zen-browser, ... }:
  let
    # Helper to avoid repeating common patterns
    mkNixosHost = { system, hostname, extraModules ? [] }: nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        # Host-specific config
        ./hosts/${hostname}/default.nix

        # Shared modules (used by ALL NixOS hosts)
        ./modules/shared/common.nix
        ./modules/shared/cli-tools.nix
        ./modules/nixos/common.nix
        sops-nix.nixosModules.sops

        # Home Manager as a NixOS module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.zirondi = import ./modules/shared/home.nix;
        }
      ] ++ extraModules;
    };
  in
  {
    # =====================================================
    # NixOS Configurations
    # =====================================================

    nixosConfigurations = {

      # --- Acer Nitro 5 (Ryzen 7, GTX 1650, x86_64) ---
      nitro5 = mkNixosHost {
        system = "x86_64-linux";
        hostname = "nitro5";
        extraModules = [
          # NVIDIA module — only on real hardware
          ./hosts/nitro5/nvidia.nix

          # VS Code Remote Server
          vscode-server.nixosModules.default
          ({ pkgs, ... }: {
            services.vscode-server = {
              enable = true;
              enableFHS = true;
              nodejsPackage = pkgs.nodejs;
            };
            environment.systemPackages = [
              zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
            ];
          })
        ];
      };

      # --- Nitro 5 VM target (for testing on Mac, no NVIDIA) ---
      nitro5-vm = mkNixosHost {
        system = "x86_64-linux";
        hostname = "nitro5";
        extraModules = [
          vscode-server.nixosModules.default
          ({ modulesPath, lib, pkgs, ... }: {
            imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
            boot.initrd.availableKernelModules = lib.mkForce [ "virtio_pci" "virtio_blk" "virtio_net" ];
            boot.kernelModules = lib.mkForce [ ];
            fileSystems."/" = lib.mkForce { device = "/dev/vda1"; fsType = "ext4"; };
            boot.loader.grub.device = lib.mkForce "/dev/vda";
            services.vscode-server = {
              enable = true;
              nodejsPackage = pkgs.nodejs;
            };
          })
        ];
      };

      # --- Raspberry Pi 3 (aarch64) ---
      rpi3 = mkNixosHost {
        system = "aarch64-linux";
        hostname = "rpi3";
        extraModules = [
          nixos-hardware.nixosModules.raspberry-pi-3
        ];
      };

      # --- Hetzner VPS (Finland, x86_64) ---
      hetzner = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Host-specific config (includes disk-config.nix)
          ./hosts/hetzner/default.nix
          # Shared modules
          ./modules/shared/common.nix
          ./modules/shared/cli-tools.nix
          ./modules/nixos/common.nix
          sops-nix.nixosModules.sops
          # disko module
          disko.nixosModules.disko
          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.zirondi = import ./modules/shared/home.nix;
          }
        ];
      };
    };

    # =====================================================
    # macOS (nix-darwin) Configurations
    # =====================================================

    darwinConfigurations = {

      # --- Mac Mini M1 ---
      macmini = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/macmini/default.nix
          ./modules/shared/common.nix
          ./modules/shared/cli-tools.nix
          ./modules/darwin/homebrew.nix
          ./modules/darwin/ollama.nix
          ./modules/darwin/podman.nix
          ./modules/darwin/keyboard.nix
          sops-nix.darwinModules.sops

          # Home Manager as a nix-darwin module
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.zirondi = import ./modules/shared/home.nix;
          }
        ];
      };
    };
  };
}
