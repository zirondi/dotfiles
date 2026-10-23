{
  description = "Zirondi's cross-platform system configurations";

  inputs = {
    # --- Core ---
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # --- macOS (nix-darwin) ---
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Home Manager ---
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Hardware quirks for specific devices ---
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nixos-hardware,
      disko,
      sops-nix,
      vscode-server,
      zen-browser,
      ...
    }:
    let
      # Systems we evaluate tooling (formatter, dev shell, checks) for
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ] (
          system: f nixpkgs.legacyPackages.${system}
        );

      # Home Manager wiring shared by ALL hosts (NixOS and Darwin)
      hmModule = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        # Never clobber pre-existing physical files when instantiating symlinks
        home-manager.backupFileExtension = "backup";
        home-manager.users.zirondi = import ./modules/shared/home.nix;
      };

      # Helper to avoid repeating common patterns
      mkNixosHost =
        {
          system,
          hostname,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
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
            hmModule
          ]
          ++ extraModules;
        };
    in
    {
      # =====================================================
      # Tooling: `nix fmt`, `nix develop`, `nix flake check`
      # =====================================================

      formatter = forAllSystems (pkgs: pkgs.nixfmt);

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            just
            shellcheck
            nixfmt
            statix
            deadnix
            sops
            age
            ssh-to-age
            nixos-anywhere # Remote installs (docs/nixos_anywhere_guide.md)
          ];
        };
      });

      checks = forAllSystems (pkgs: {
        # Lint every maintenance script (same invocation as `just lint`)
        shellcheck = pkgs.runCommand "shellcheck-scripts" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
          cd ${./scripts}
          shellcheck -x -S warning *.sh lib/*.sh gen-passphrase rbw-menu
          shellcheck -S warning ${./configs/clash-party/crypt.sh}
          touch $out
        '';

        # Fail when a Nix file is not formatted (fix with `just fmt`)
        nixfmt = pkgs.runCommand "nixfmt-check" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
          find ${self} -name '*.nix' -exec nixfmt --check {} +
          touch $out
        '';
      });

      # =====================================================
      # NixOS Configurations
      # =====================================================

      nixosConfigurations = {

        # --- Acer Nitro 5 (Ryzen 7, GTX 1650, x86_64) ---
        nitro5 = mkNixosHost {
          system = "x86_64-linux";
          hostname = "nitro5";
          extraModules = [
            ./modules/shared/cli-dev.nix
            ./modules/shared/ferdium.nix
            ./modules/shared/calendar.nix

            # NVIDIA module and disk layout — only on real hardware
            ./hosts/nitro5/nvidia.nix
            disko.nixosModules.disko
            ./hosts/nitro5/disk-config.nix

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
            ./modules/shared/cli-dev.nix
            ./modules/shared/ferdium.nix
            ./modules/shared/calendar.nix
            vscode-server.nixosModules.default
            (
              {
                modulesPath,
                lib,
                pkgs,
                ...
              }:
              {
                imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
                boot.initrd.availableKernelModules = lib.mkForce [
                  "virtio_pci"
                  "virtio_blk"
                  "virtio_net"
                ];
                boot.kernelModules = lib.mkForce [ ];
                fileSystems."/" = lib.mkForce {
                  device = "/dev/vda1";
                  fsType = "ext4";
                };
                boot.loader.grub.device = lib.mkForce "/dev/vda";
                services.vscode-server = {
                  enable = true;
                  nodejsPackage = pkgs.nodejs;
                };
              }
            )
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
        hetzner = mkNixosHost {
          system = "x86_64-linux";
          hostname = "hetzner";
          extraModules = [
            # disko handles partitioning (see hosts/hetzner/disk-config.nix)
            disko.nixosModules.disko
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
            ./modules/shared/cli-dev.nix
            ./modules/shared/ferdium.nix
            ./modules/shared/calendar.nix
            ./modules/darwin/homebrew.nix
            ./modules/darwin/ollama.nix
            ./modules/darwin/podman.nix
            ./modules/darwin/keyboard.nix
            ./modules/darwin/aerospace.nix
            ./modules/darwin/sketchybar.nix
            ./modules/darwin/desktop.nix
            ./modules/darwin/backup.nix
            ./modules/darwin/cloudflared.nix
            sops-nix.darwinModules.sops

            # Home Manager as a nix-darwin module
            home-manager.darwinModules.home-manager
            hmModule
          ];
        };
      };
    };
}
