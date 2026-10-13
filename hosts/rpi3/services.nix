{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Enable IP forwarding for Tailscale Subnet Router
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

  # Tailscale Setup
  services.tailscale = {
    enable = true;
    # NixOS handles tailscale startup automatically
  };

  # Enable Podman as the container engine
  virtualisation.podman = {
    enable = true;
    # Create an alias for docker=podman
    dockerCompat = true;
    # Off on purpose: the bridge DNS (aardvark) wants port 53 on the bridge
    # address, which Pi-hole already holds on every address of the host
    defaultNetwork.settings.dns_enabled = lib.mkForce false;
  };

  # Secrets (sops-nix): decrypted at activation with the host SSH key into
  # /run/secrets. Edit with `sops hosts/rpi3/secrets.sops.yaml`.
  sops = {
    defaultSopsFile = ./secrets.sops.yaml;
    secrets.pihole_env.restartUnits = [ "podman-pihole.service" ];
    secrets.cloudflared_env.restartUnits = [ "podman-cloudflared.service" ];
  };

  # OCI Containers via Podman
  # Image tags are pinned; bump them here on purpose instead of tracking
  # :latest/:stable.
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      # Pi-hole Container
      pihole = {
        image = "docker.io/pihole/pihole:2026.07.2";
        # When using host networking, ports are bound directly, so we don't map them manually.
        extraOptions = [
          "--network=host"
          "--cap-add=NET_ADMIN"
          # dnsmasq refuses to start without it; Podman drops NET_RAW by default
          "--cap-add=NET_RAW"
        ];
        volumes = [
          "/var/lib/pihole/etc-pihole:/etc/pihole"
          "/var/lib/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
        ];
        environment = {
          TZ = "America/Sao_Paulo";
        };
        # WEBPASSWORD
        environmentFiles = [ config.sops.secrets.pihole_env.path ];
        autoStart = true;
      };

      # Ferdium Server: syncs services and workspaces between Ferdium clients
      ferdium-server = {
        image = "docker.io/ferdium/ferdium-server:2.0.13";
        # Published on the Pi's tailnet address only (http://rpi3:3333).
        # A port published on every address is reachable from the LAN even
        # when the firewall does not list it: Podman forwards it before the
        # NixOS input rules are consulted.
        ports = [ "100.69.134.71:3333:3333" ];
        volumes = [
          "/var/lib/ferdium-server/data:/data"
          "/var/lib/ferdium-server/recipes:/app/recipes"
        ];
        environment = {
          TZ = "America/Sao_Paulo";
          NODE_ENV = "production";
          APP_URL = "http://rpi3:3333";
          DB_CONNECTION = "sqlite";
          DATA_DIR = "/data";
          IS_CREATION_ENABLED = "true";
          IS_DASHBOARD_ENABLED = "true";
          # Turn this off once the accounts exist
          IS_REGISTRATION_ENABLED = "true";
          # Needed for the public recipe library, not only custom recipes
          CONNECT_WITH_FRANZ = "true";
        };
        extraOptions = [
          "--memory=256m"
          "--security-opt=no-new-privileges"
        ];
        autoStart = true;
      };

      # Cloudflare Tunnel Container
      cloudflared = {
        image = "docker.io/cloudflare/cloudflared:2026.7.3";
        cmd = [
          "tunnel"
          "--no-autoupdate"
          "run"
        ];
        # TUNNEL_TOKEN
        environmentFiles = [ config.sops.secrets.cloudflared_env.path ];
        extraOptions = [ "--network=host" ];
        autoStart = true;
      };
    };
  };

  # Firewall Configuration
  networking.firewall = {
    enable = true;
    # Open necessary ports on all interfaces
    allowedTCPPorts = [
      53 # Pi-hole DNS
      80 # Pi-hole Web Admin
      19999 # Netdata Web
    ];
    allowedUDPPorts = [
      53 # Pi-hole DNS
      67 # Pi-hole DHCP Server
    ];
  };

  # Automated Google Drive Backups via Rclone
  # Skipped until `rclone config` has been run once as root on the host.
  systemd.services.rclone-backup = {
    description = "Backup important data to Google Drive";
    unitConfig.ConditionPathExists = "/root/.config/rclone/rclone.conf";
    environment.RCLONE_CONFIG = "/root/.config/rclone/rclone.conf";
    script = ''
      # Sync Ferdium Server (accounts, services and workspaces)
      ${pkgs.rclone}/bin/rclone sync /var/lib/ferdium-server gdrive:servers/rpi3-backup/ferdium-server --fast-list

      # Sync Pi-hole (Excluding any stray env files)
      ${pkgs.rclone}/bin/rclone sync /var/lib/pihole gdrive:servers/rpi3-backup/pihole --exclude="*.env" --fast-list
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers.rclone-backup = {
    description = "Run daily backup to Google Drive";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
    };
  };

  # Ensure the necessary persistent directories exist before containers start
  systemd.tmpfiles.rules = [
    "d /var/lib/ferdium-server/data 0755 root root -"
    "d /var/lib/ferdium-server/recipes 0755 root root -"
    "d /var/lib/pihole/etc-pihole 0755 root root -"
    "d /var/lib/pihole/etc-dnsmasq.d 0755 root root -"
  ];
}
