{
  config,
  pkgs,
  ...
}:

# What the hetzner backup copies (see modules/nixos/backup.nix).
#
# The containers run under rootless Podman as zirondi, so their files belong
# to sub-UIDs and the commands below reach them through that user. Databases
# are copied by their own tools instead of from the live files:
#   nextcloud  pg_dump, with Nextcloud in maintenance mode during the backup
#   n8n        pg_dump
#   aliasvault pg_dump (vaults, aliases and received mail; the files it reads
#              from /run/secrets live in its SOPS files)
#   vaultwarden  SQLite online backup (backup.sqlite, as zirondi)
#   stalwart   stopped while Restic reads its RocksDB directory, started again
#              in cleanup (a few seconds without SMTP; senders retry)
let
  volumes = "/home/zirondi/volumes";
  podman = "${config.virtualisation.podman.package}/bin/podman";
  asUser = ''${pkgs.util-linux}/bin/runuser -u zirondi -- env XDG_RUNTIME_DIR="/run/user/$(id -u zirondi)"'';
in
{
  imports = [ ../../modules/nixos/backup.nix ];

  # Rootless Podman may need the newuidmap/newgidmap setuid wrappers
  systemd.services.restic-backups-gdrive.path = [ "/run/wrappers" ];

  backup = {
    enable = true;

    paths = [
      "${volumes}/vaultwarden/data"
      "${volumes}/stalwart"
      "${volumes}/traefik/certs"
      "${volumes}/n8n/data"
      "${volumes}/n8n/files"
      "${volumes}/n8n/n8n-files"
      # Only what is not Nextcloud's own code: the image reinstalls the rest
      "${volumes}/nextcloud/html/config"
      "${volumes}/nextcloud/html/data"
      "${volumes}/nextcloud/html/custom_apps"
      "${volumes}/nextcloud/html/themes"
    ];

    sqlite.vaultwarden = {
      path = "${volumes}/vaultwarden/data/db.sqlite3";
      owner = "zirondi";
    };

    exclude = [
      # Rebuilt on demand
      "${volumes}/vaultwarden/data/icon_cache"
      "${volumes}/vaultwarden/data/tmp"
      "${volumes}/nextcloud/html/data/appdata_*/preview"
      "*.log"
    ];

    prepare = ''
      ${asUser} ${podman} exec -u www-data nextcloud php occ maintenance:mode --on
      ${asUser} ${podman} exec nextcloud-db pg_dump -U nextcloud -d nextcloud -Fc > "$DUMPS/nextcloud.pgdump"
      ${asUser} ${podman} exec n8n-postgres pg_dump -U n8n -d n8n -Fc > "$DUMPS/n8n.pgdump"
      ${asUser} ${podman} exec aliasvault-postgres pg_dump -U aliasvault -d aliasvault -Fc > "$DUMPS/aliasvault.pgdump"
      ${asUser} ${podman} stop stalwart-mail
    '';

    # Each step on its own: one failing must not keep the others from running
    cleanup = ''
      ${asUser} ${podman} start stalwart-mail || true
      ${asUser} ${podman} exec -u www-data nextcloud php occ maintenance:mode --off || true
    '';
  };
}
