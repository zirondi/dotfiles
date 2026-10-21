{
  config,
  lib,
  pkgs,
  ...
}:

# Daily Restic backup of a server to Google Drive (through rclone).
#
# Each host sets `backup.enable`, its paths and the commands that make its
# databases consistent before the copy. The repository is
# gdrive:backups/<hostname>, one per host, all with the same Restic password.
# Both secrets come from the host's sops file (defaultSopsFile):
#   restic_password  the repository password (also kept on paper and in the vault)
#   rclone_conf      an rclone.conf with a `gdrive` remote (scope drive.file)
let
  cfg = config.backup;
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
      repository = "rclone:gdrive:backups/${config.networking.hostName}";
      passwordFile = config.sops.secrets.restic_password.path;
      rcloneConfigFile = config.sops.secrets.rclone_conf.path;
      paths = cfg.paths ++ [ "/var/backup/dumps" ];
      inherit (cfg) exclude;
      backupPrepareCommand = ''
        set -euo pipefail
        export DUMPS=/var/backup/dumps
        rm -rf "$DUMPS"
        install -d -m 700 "$DUMPS"
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

    environment.systemPackages = [ pkgs.restic ];
  };
}
