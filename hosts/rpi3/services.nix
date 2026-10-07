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

  # OCI Containers via Podman
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      # Home Assistant Container
      homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
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
        image = "pihole/pihole:latest";
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
        # Load secrets from a local file (for WEBPASSWORD).
        # To create this file on the Pi, run:
        # sudo mkdir -p /var/lib/pihole
        # echo 'WEBPASSWORD=your_secure_password' | sudo tee /var/lib/pihole/secrets.env
        # sudo chmod 600 /var/lib/pihole/secrets.env
        environmentFiles = [ "/var/lib/pihole/secrets.env" ];
        autoStart = true;
      };

      # Cloudflare Tunnel Container
      cloudflared = {
        image = "cloudflare/cloudflared:latest";
        cmd = [ "tunnel" "--no-autoupdate" "run" ];
        # Load Cloudflare tunnel token.
        # To create this file on the Pi, run:
        # sudo mkdir -p /var/lib/cloudflared
        # echo 'TUNNEL_TOKEN=your_actual_token_here' | sudo tee /var/lib/cloudflared/token.env
        # sudo chmod 600 /var/lib/cloudflared/token.env
        environmentFiles = [ "/var/lib/cloudflared/token.env" ];
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
  systemd.services.rclone-backup = {
    description = "Backup important data to Google Drive";
    script = ''
      # Sync Home Assistant (Excluding large log/db files to save space/time)
      ${pkgs.rclone}/bin/rclone sync /var/lib/homeassistant gdrive:servers/rpi3-backup/homeassistant --exclude="*.log" --exclude="*.db" --fast-list
      
      # Sync Pi-hole (Excluding secrets.env for security)
      ${pkgs.rclone}/bin/rclone sync /var/lib/pihole gdrive:servers/rpi3-backup/pihole --exclude="*.env" --fast-list
      
      # Sync NixOS Config
      ${pkgs.rclone}/bin/rclone sync /etc/nixos gdrive:servers/rpi3-backup/nixos --fast-list
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
    "d /var/lib/cloudflared 0700 root root -"
  ];
}
