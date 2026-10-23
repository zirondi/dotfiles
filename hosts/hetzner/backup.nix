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
#   vaultwarden  SQLite online backup
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
    # Off until rclone_conf exists in this host's sops file (ORDEM.md, block 7:
    # Drive OAuth). sops-nix checks every declared secret at build time, so
    # enabling it earlier fails the whole system build.
    enable = false;

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

    exclude = [
      # Live database files; the dumps carry a consistent copy
      "${volumes}/vaultwarden/data/db.sqlite3*"
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
      # zirondi owns the database; it writes the copy into a private
      # directory of its own, then root moves it into the dumps
      vw_tmp="$(mktemp -d)"
      chown zirondi "$vw_tmp"
      ${asUser} ${pkgs.sqlite}/bin/sqlite3 ${volumes}/vaultwarden/data/db.sqlite3 ".backup '$vw_tmp/vaultwarden.sqlite3'"
      mv "$vw_tmp/vaultwarden.sqlite3" "$DUMPS/vaultwarden.sqlite3"
      rmdir "$vw_tmp"
      ${asUser} ${podman} stop stalwart-mail
    '';

    # Each step on its own: one failing must not keep the others from running
    cleanup = ''
      ${asUser} ${podman} start stalwart-mail || true
      ${asUser} ${podman} exec -u www-data nextcloud php occ maintenance:mode --off || true
    '';
  };
}
