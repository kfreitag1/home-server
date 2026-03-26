{ config, pkgs, ... }:

# TODO: replace with permanent backup solution with SnapRAID
{
  # Rsync backup service for syncing storage to backup drive
  systemd.services.rsync-backup = {
    description = "Rsync backup of storage to backup drive";

    # Ensure mount points are available before running
    after = [ "local-fs.target" ];
    requires = [ "mnt-storage.mount" "mnt-backup.mount" ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";

      # Rsync command with common backup options
      ExecStart = pkgs.writeShellScript "rsync-backup" ''
        set -e

        echo "[$(date)] Starting backup..."

        # Ensure backup directory exists
        mkdir -p /mnt/backup

        # Backup storage directory
        echo "Syncing /mnt/storage/storage..."
        ${pkgs.rsync}/bin/rsync -avh --delete \
          --info=progress2 \
          /mnt/storage/storage/ \
          /mnt/backup/storage/

        # Backup docs directory
        echo "Syncing /mnt/storage/docs..."
        ${pkgs.rsync}/bin/rsync -avh --delete \
          --info=progress2 \
          /mnt/storage/docs/ \
          /mnt/backup/docs/

        # Backup timemachine directory
        echo "Syncing /mnt/storage/timemachine..."
        ${pkgs.rsync}/bin/rsync -avh --delete \
          --info=progress2 \
          /mnt/storage/timemachine/ \
          /mnt/backup/timemachine/

        # Backup notes directory
        echo "Syncing /mnt/storage/notes..."
        ${pkgs.rsync}/bin/rsync -avh --delete \
          --info=progress2 \
          /mnt/storage/notes/ \
          /mnt/backup/notes/

        # Backup immich directory
        echo "Syncing /mnt/storage/immich..."
        ${pkgs.rsync}/bin/rsync -avh --delete \
          --info=progress2 \
          /mnt/storage/immich/ \
          /mnt/backup/immich/

        # Backup home directory
        echo "Syncing home directory..."
        ${pkgs.rsync}/bin/rsync -avh --delete \
          --info=progress2 \
          --exclude='.cache' \
          --exclude='.local/share/Trash' \
          /home/kieran/ \
          /mnt/backup/home/

        echo "[$(date)] Backup completed successfully"
      '';

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # Timer to run backup daily at 3am
  systemd.timers.rsync-backup = {
    description = "Timer for rsync backup (daily at 3am)";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      RandomizedDelaySec = "5min";
    };
  };
}
