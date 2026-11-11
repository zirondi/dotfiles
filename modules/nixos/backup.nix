{
  config,
  lib,
  pkgs,
  ...
}:

# Daily Restic backup of a server to Google Drive (through rclone).
#
# Each host sets `backup.enable`, its paths and the commands that make its
# databases consistent before the copy. The repository is gdrive:restic, one
# per host. Each host has its own Restic password and its own Google Cloud
# project for the OAuth client: drive.file lets a token see what any client of
# the same project created, so a shared project would let root on one host
# list and delete the others' backups.
#
# The token cannot see folders the user made by hand, so the remote root is
# pinned with root_folder_id to a backup-<host> folder that the token created
# itself (scratch/wizards/sprint.sh, stage 6). Moving that folder in Drive
# (into servers/) keeps its id and the token's access.
# Both secrets come from the host's sops file (defaultSopsFile):
#   restic_password  the repository password (also kept on paper and in the vault)
#   rclone_conf      an rclone.conf with a `gdrive` remote (scope drive.file,
#                    root_folder_id = the host's backup-<host> folder)
let
  cfg = config.backup;
  sqlite3 = "${pkgs.sqlite}/bin/sqlite3";

  # A consistent copy of one SQLite database into $DUMPS/<name>.sqlite3. With
  # an owner (rootless Podman, whose files root cannot open as itself), the
  # owner writes it into a private directory of its own and root moves it.
  dumpSqlite =
    name: db:
    if db.owner == null then
      ''
        ${sqlite3} ${db.path} ".backup '$DUMPS/${name}.sqlite3'"
      ''
    else
      ''
        tmp="$(mktemp -d)"
        chown ${db.owner} "$tmp"
        ${pkgs.util-linux}/bin/runuser -u ${db.owner} -- ${sqlite3} ${db.path} ".backup '$tmp/${name}.sqlite3'"
        mv "$tmp/${name}.sqlite3" "$DUMPS/${name}.sqlite3"
        rmdir "$tmp"
      '';
in
{
  options.backup = {
    enable = lib.mkEnableOption "the daily Restic backup to Google Drive";

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Paths to back up. The dumps directory is always added.";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Restic exclude patterns.";
    };

    sqlite = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            path = lib.mkOption {
              type = lib.types.str;
              description = "The live database file.";
            };
            owner = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "User that runs the copy, when root cannot open the file itself.";
            };
          };
        }
      );
      default = { };
      description = ''
        SQLite databases inside the backed-up paths. Each one is excluded as a
        live file (with its -wal and -shm) and copied consistently with
        `.backup` into $DUMPS/<name>.sqlite3 before the backup.
      '';
    };

    prepare = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Runs before the backup, as root, with $DUMPS pointing at an empty
        directory that is backed up. Database dumps go there. A failure here
        aborts the backup.
      '';
    };

    cleanup = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Runs after the backup, whether it succeeded or not (leave maintenance
        mode, start what prepare stopped).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.restic_password = { };
    sops.secrets.rclone_conf = { };

    services.restic.backups.gdrive = {
      initialize = true;
      repository = "rclone:gdrive:restic";
      passwordFile = config.sops.secrets.restic_password.path;
      rcloneConfigFile = config.sops.secrets.rclone_conf.path;
      paths = cfg.paths ++ [ "/var/backup/dumps" ];
      exclude = cfg.exclude ++ lib.mapAttrsToList (_: db: "${db.path}*") cfg.sqlite;
      backupPrepareCommand = ''
        set -euo pipefail
        export DUMPS=/var/backup/dumps
        rm -rf "$DUMPS"
        install -d -m 700 "$DUMPS"
        ${lib.concatStrings (lib.mapAttrsToList dumpSqlite cfg.sqlite)}
        ${cfg.prepare}
      '';
      # The dumps hold plain copies of the databases: never leave them behind
      backupCleanupCommand = ''
        ${cfg.cleanup}
        rm -rf /var/backup/dumps
      '';
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
      ];
      timerConfig = {
        OnCalendar = "04:00";
        RandomizedDelaySec = "20m";
        Persistent = true;
      };
    };

    # Restic runs the rclone binary for rclone: repositories
    systemd.services.restic-backups-gdrive.path = [ pkgs.rclone ];

    # rclone too, to inspect the remote by hand (`rclone --config ... lsf gdrive:`)
    environment.systemPackages = [
      pkgs.restic
      pkgs.rclone
    ];
  };
}
