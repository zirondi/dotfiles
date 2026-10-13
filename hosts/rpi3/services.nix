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
    # CF_DNS_API_TOKEN, for the DNS-01 challenge of the wildcard certificate
    secrets.traefik_env.restartUnits = [ "traefik.service" ];
  };

  # Reverse proxy for the per-host names (service.rpi3.leazirondi.com.br).
  # Runs as a plain NixOS service: the routes are static, so there is no
  # container socket to expose. Ports 80 and 443 are not opened in the
  # firewall, which leaves them reachable over the tailnet only (tailscale0 is
  # a trusted interface). The public wildcard record points at the Pi's
  # tailnet address.
  services.traefik = {
    enable = true;
    environmentFiles = [ config.sops.secrets.traefik_env.path ];
    staticConfigOptions = {
      global.sendAnonymousUsage = false;
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        websecure = {
          address = ":443";
          http.tls = {
            certResolver = "cloudflare";
            domains = [
              {
                main = "rpi3.leazirondi.com.br";
                sans = [ "*.rpi3.leazirondi.com.br" ];
              }
            ];
          };
        };
      };
      certificatesResolvers.cloudflare.acme = {
        email = "acme@leazirondi.com.br";
        storage = "${config.services.traefik.dataDir}/acme.json";
        dnsChallenge = {
          provider = "cloudflare";
          resolvers = [
            "1.1.1.1:53"
            "1.0.0.1:53"
          ];
        };
      };
    };
    # One router and one backend per service; add new names here
    dynamicConfigOptions.http = {
      routers = {
        ferdium = {
          rule = "Host(`ferdium.rpi3.leazirondi.com.br`)";
          entryPoints = [ "websecure" ];
          service = "ferdium";
        };
        pihole = {
          rule = "Host(`pihole.rpi3.leazirondi.com.br`)";
          entryPoints = [ "websecure" ];
          service = "pihole";
          middlewares = [ "pihole-admin" ];
        };
      };
      # Pi-hole answers 403 on "/"; its UI lives under /admin
      middlewares.pihole-admin.redirectRegex = {
        regex = "^https://pihole\\.rpi3\\.leazirondi\\.com\\.br/?$";
        replacement = "https://pihole.rpi3.leazirondi.com.br/admin/";
      };
      services = {
        ferdium.loadBalancer.servers = [ { url = "http://127.0.0.1:3333"; } ];
        pihole.loadBalancer.servers = [ { url = "http://127.0.0.1:8081"; } ];
      };
    };
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
          # Web UI off 80/443, which belong to Traefik. Port 8081 stays open
          # on the LAN as a fallback (http://10.0.0.10:8081/admin) for when
          # the tailnet or the proxy is down.
          FTLCONF_webserver_port = "8081o,[::]:8081o";
        };
        # WEBPASSWORD
        environmentFiles = [ config.sops.secrets.pihole_env.path ];
        autoStart = true;
      };

      # Ferdium Server: syncs services and workspaces between Ferdium clients
      ferdium-server = {
        image = "docker.io/ferdium/ferdium-server:2.0.13";
        # Loopback only; Traefik serves it as ferdium.rpi3.leazirondi.com.br.
        # A port published on every address is reachable from the LAN even
        # when the firewall does not list it: Podman forwards it before the
        # NixOS input rules are consulted.
        ports = [ "127.0.0.1:3333:3333" ];
        volumes = [
          "/var/lib/ferdium-server/data:/data"
          "/var/lib/ferdium-server/recipes:/app/recipes"
        ];
        environment = {
          TZ = "America/Sao_Paulo";
          NODE_ENV = "production";
          APP_URL = "https://ferdium.rpi3.leazirondi.com.br";
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
      8081 # Pi-hole Web Admin (fallback; the proxied name is tailnet-only)
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
