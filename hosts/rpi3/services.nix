{ config, pkgs, lib, ... }:

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
    defaultNetwork.settings.dns_enabled = true;
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
      # Home Assistant Container
      homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:2026.8.0";
        volumes = [ "/var/lib/homeassistant:/config" ];
        environment = {
          TZ = "America/Sao_Paulo";
        };
        extraOptions = [
          "--network=host"
          "--privileged"
        ];
        autoStart = true;
      };

      # Pi-hole Container
      pihole = {
        image = "pihole/pihole:2026.07.2";
        # When using host networking, ports are bound directly, so we don't map them manually.
        extraOptions = [
          "--network=host"
          "--cap-add=NET_ADMIN"
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

      # Cloudflare Tunnel Container
      cloudflared = {
        image = "cloudflare/cloudflared:2026.7.3";
        cmd = [ "tunnel" "--no-autoupdate" "run" ];
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
      53    # Pi-hole DNS
      80    # Pi-hole Web Admin
      8123  # Home Assistant
      19999 # Netdata Web
    ];
    allowedUDPPorts = [ 
      53    # Pi-hole DNS
      67    # Pi-hole DHCP Server
    ];
  };

  # Automated Google Drive Backups via Rclone
  # Skipped until `rclone config` has been run once as root on the host.
  systemd.services.rclone-backup = {
    description = "Backup important data to Google Drive";
    unitConfig.ConditionPathExists = "/root/.config/rclone/rclone.conf";
    environment.RCLONE_CONFIG = "/root/.config/rclone/rclone.conf";
    script = ''
      # Sync Home Assistant (Excluding large log/db files to save space/time)
      ${pkgs.rclone}/bin/rclone sync /var/lib/homeassistant gdrive:servers/rpi3-backup/homeassistant --exclude="*.log" --exclude="*.db" --fast-list

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
    "d /var/lib/homeassistant 0755 root root -"
    "d /var/lib/pihole/etc-pihole 0755 root root -"
    "d /var/lib/pihole/etc-dnsmasq.d 0755 root root -"
  ];
}
