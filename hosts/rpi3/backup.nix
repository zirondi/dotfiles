{ pkgs, ... }:

# What the rpi3 backup copies (see modules/nixos/backup.nix). The containers
# run as root here, so their directories are readable directly.
#   ferdium-server  SQLite online backup of the accounts, services and
#                   workspaces; the recipe store is rebuilt by the entrypoint
#   pihole          configuration only; gravity and the query history are
#                   rebuilt or disposable
#   homeassistant   what was left when Home Assistant was removed
{
  imports = [ ../../modules/nixos/backup.nix ];

  backup = {
    enable = true;

    paths = [
      "/var/lib/ferdium-server/data"
      "/var/lib/pihole"
      "/var/lib/homeassistant"
    ];

    exclude = [
      "/var/lib/ferdium-server/data/ferdium.sqlite*"
      "/var/lib/pihole/etc-pihole/gravity*.db"
      "/var/lib/pihole/etc-pihole/gravity_backups"
      "/var/lib/pihole/etc-pihole/pihole-FTL.db*"
      "/var/lib/pihole/etc-pihole/listsCache"
      "*.log*"
    ];

    prepare = ''
      ${pkgs.sqlite}/bin/sqlite3 /var/lib/ferdium-server/data/ferdium.sqlite ".backup '$DUMPS/ferdium.sqlite'"
    '';
  };
}
