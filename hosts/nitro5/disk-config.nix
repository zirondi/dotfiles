# Disk layout for nixos-anywhere / disko (Kingston NV3 500 GB NVMe)
# GPT: 1 GiB EFI system partition + LUKS2 with ext4 for everything else.
# The passphrase is typed at boot; during install nixos-anywhere puts it in
# /tmp/disk.key (--disk-encryption-keys), and it never enters the repo.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-KINGSTON_SNV3S500G_50026B7686D3408F";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            passwordFile = "/tmp/disk.key";
            settings.allowDiscards = true; # TRIM on the SSD
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
