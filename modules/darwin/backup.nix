{
  config,
  lib,
  pkgs,
  ...
}:

# Daily Restic backup of the Mac to Google Drive, the macOS counterpart of
# modules/nixos/backup.nix (same retention, repository gdrive:backups/<backup.name>).
# Only what no repository holds: keys, local state of the AI agents, and the
# folders the host lists in backup.paths.
#
# Runs as a launchd user agent, as the primary user, so it reads that user's
# files without Full Disk Access. Both secrets come from the host's sops file
# and are owned by the primary user:
#   restic_password  the repository password (also kept on paper and in the vault)
#   rclone_conf      an rclone.conf with a `gdrive` remote (scope drive.file)
let
  cfg = config.backup;
  user = config.system.primaryUser;
  home = config.users.users.${user}.home;
  secrets = config.sops.secrets;

  run = pkgs.writeShellScript "restic-backup" ''
    set -euo pipefail
    export RESTIC_REPOSITORY="rclone:gdrive:backups/${cfg.name}"
    export RESTIC_PASSWORD_FILE=${secrets.restic_password.path}
    export RCLONE_CONFIG=${secrets.rclone_conf.path}
    export PATH=${lib.makeBinPath [ pkgs.rclone ]}:$PATH
    restic=${pkgs.restic}/bin/restic

    $restic cat config >/dev/null 2>&1 || $restic init
    $restic backup --exclude-caches ${
      lib.concatMapStringsSep " " (e: "--exclude ${lib.escapeShellArg e}") cfg.exclude
    } ${lib.escapeShellArgs cfg.paths}
    $restic forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 12
  '';
in
{
  options.backup = {
    enable = lib.mkEnableOption "the daily Restic backup of this Mac to Google Drive";

    # networking.hostName is null on nix-darwin unless set, and setting it
    # renames the machine, so the repository name is given explicitly
    name = lib.mkOption {
      type = lib.types.str;
      description = "Repository name under gdrive:backups/ (the flake host name).";
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Absolute paths to back up.";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Restic exclude patterns.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.restic_password.owner = user;
    sops.secrets.rclone_conf.owner = user;

    environment.systemPackages = [ pkgs.restic ];

    launchd.user.agents.restic-backup.serviceConfig = {
      Label = "com.zirondi.restic-backup";
      ProgramArguments = [ "${run}" ];
      StartCalendarInterval = [
        {
          Hour = 4;
          Minute = 30;
        }
      ];
      # A Mac asleep at 04:30 runs the job when it wakes up
      StandardOutPath = "${home}/Library/Logs/restic-backup.log";
      StandardErrorPath = "${home}/Library/Logs/restic-backup.log";
    };
  };
}
