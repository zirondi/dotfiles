# Declarative disk layout for nixos-anywhere / disko
# Adjust /dev/sda to match your server's disk (check with `lsblk`)
{
  disko.devices = {
    disk.main = {
      device = "/dev/sda";  # Hetzner VPS typically uses /dev/sda
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          # BIOS boot partition (needed for GRUB on legacy BIOS servers)
          boot = {
            size = "1M";
            type = "EF02";  # BIOS boot partition
          };
          # EFI System Partition (needed for UEFI servers)
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          # Root partition — takes all remaining space
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}