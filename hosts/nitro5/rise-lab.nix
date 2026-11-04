# RISE class mode: insecure services on the wired LAN, so students can watch
# credentials cross the network in clear text (Wireshark on this host,
# projected). A specialisation, so it is switched on and off in the room
# without a rebuild or network access:
#
#   on:  sudo /run/current-system/specialisation/rise-lab/bin/switch-to-configuration test
#   off: sudo /run/current-system/bin/switch-to-configuration test
#
# Ports open only on the wired interface. The Wi-Fi (eduroam) carries a public
# address and stays closed; the UNESP perimeter also filters inbound traffic.
#
# | Port        | Service                                                  |
# | 21, 50000+  | FTP, anonymous only, read-only (/srv/ftp)                |
# | 23          | telnet, fake login prompt: no shell, nothing is checked  |
# | 4444        | ncat chat room (`ncat <host> 4444` or `telnet <host> 4444`) |
# | 8000        | free for the class web app, started by hand              |
# | 9418        | git daemon, read-only mirror of /srv/git                 |
#
# Mirror a repo: `ssh nitro5 git init --bare /srv/git/<name>.git`, then
# `git push nitro5:/srv/git/<name>.git main`; students clone
# git://nitro5.local/<name>.git.
{ pkgs, ... }:

let
  lan = "enp3s0";

  # Asks for a login and a password, echoes nothing back and opens no shell:
  # the point is the clear text on the wire, not access to this host
  fakeLogin = pkgs.writeShellScript "rise-fake-login" ''
    export PATH=${pkgs.coreutils}/bin
    printf 'RISE - servidor telnet (sem criptografia)\r\n\r\nlogin: '
    IFS= read -r user
    printf 'Password: '
    stty -echo
    IFS= read -r _pass
    stty echo
    printf '\r\n\r\nBem-vindo, %s. Usuario e senha cruzaram a rede em texto claro.\r\n' "''${user%$'\r'}"
    sleep 2
  '';
in
{
  specialisation.rise-lab.configuration = {
    system.nixos.tags = [ "rise-lab" ];

    networking.firewall.interfaces.${lan} = {
      allowedTCPPorts = [
        21
        23
        4444
        8000
        9418
      ];
      # FTP passive data connections (pasv_* below)
      allowedTCPPortRanges = [
        {
          from = 50000;
          to = 50020;
        }
      ];
    };

    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };
    users.users.zirondi.extraGroups = [ "wireshark" ];
    environment.systemPackages = [
      pkgs.tcpdump
      pkgs.nmap # ncat
      pkgs.inetutils # ftp and telnet clients, to test from here
    ];

    services = {
      gitDaemon = {
        enable = true;
        basePath = "/srv/git";
        exportAll = true;
      };
      vsftpd = {
        enable = true;
        anonymousUser = true;
        anonymousUserHome = "/srv/ftp";
        extraConfig = ''
          pasv_min_port=50000
          pasv_max_port=50020
        '';
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /srv/git 0755 zirondi users -"
        "f /srv/ftp/LEIA-ME.txt 0444 root root - Usuario e senha deste login passaram em texto claro. Confira no Wireshark."
      ];

      services = {
        # The repos belong to zirondi (who pushes); git refuses to serve a
        # repo owned by another user unless safe.directory says so
        git-daemon.environment = {
          GIT_CONFIG_COUNT = "1";
          GIT_CONFIG_KEY_0 = "safe.directory";
          GIT_CONFIG_VALUE_0 = "*";
        };

        rise-telnet = {
          description = "RISE fake telnet login";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.busybox}/bin/telnetd -F -p 23 -l ${fakeLogin}";
            DynamicUser = true;
            AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
            Restart = "on-failure";
          };
        };

        rise-chat = {
          description = "RISE ncat chat room";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.nmap}/bin/ncat --listen --keep-open --chat 4444";
            DynamicUser = true;
            Restart = "on-failure";
          };
        };
      };
    };
  };
}
