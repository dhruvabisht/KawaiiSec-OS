# KawaiiSec OS Partition Layout Guide

## Overview

KawaiiSec OS uses a sophisticated partition layout designed for security, reliability, and ease of management. This document outlines the recommended partition scheme and storage management features.

## Recommended Partition Layout

### Standard Installation (Single Disk)

```
Device    Size    Type                Mount Point    Filesystem    Flags
/dev/sda1 512M    EFI System          /boot/efi      FAT32         boot, esp
/dev/sda2 1G      Linux filesystem    /boot          ext4          -
/dev/sda3 32G     Linux filesystem    /              btrfs         -
/dev/sda4 8G      Linux swap          [SWAP]         swap          -
/dev/sda5 Remain  Linux filesystem    /home          btrfs         -
```

### Advanced Installation (Multiple Disks)

For systems with multiple disks, consider this layout for better performance and redundancy:

```
Device     Size    Type                Mount Point    Filesystem    Notes
/dev/sda1  512M    EFI System          /boot/efi      FAT32         Primary disk
/dev/sda2  1G      Linux filesystem    /boot          ext4          Primary disk
/dev/sda3  32G     Linux filesystem    /              btrfs         Primary disk (SSD recommended)
/dev/sda4  8G      Linux swap          [SWAP]         swap          Primary disk
/dev/sdb1  Remain  Linux filesystem    /home          btrfs         Secondary disk (RAID optional)
/dev/sdc1  Remain  Linux filesystem    /opt/labs      btrfs         Lab storage (optional)
```

## Partition Details

### 1. EFI System Partition (/boot/efi)
- **Size**: 512MB (minimum 260MB)
- **Filesystem**: FAT32
- **Purpose**: UEFI boot loader and boot manager
- **Mount Options**: `defaults,umask=0077`

### 2. Boot Partition (/boot)
- **Size**: 1GB
- **Filesystem**: ext4
- **Purpose**: Linux kernel, initramfs, and GRUB files
- **Mount Options**: `defaults,nodev,nosuid,noexec`

### 3. Root Partition (/)
- **Size**: 32GB (minimum 20GB)
- **Filesystem**: Btrfs with subvolumes
- **Purpose**: System files, applications, and OS
- **Features**: Snapshots, compression, OverlayFS support

#### Btrfs Subvolume Layout for Root:
```
/dev/sda3 (btrfs volume)
├── @             -> /           (root subvolume)
├── @snapshots    -> /.snapshots (snapshot storage)
├── @var          -> /var        (variable data)
├── @tmp          -> /tmp        (temporary files)
└── @opt          -> /opt        (optional software)
```

### 4. Swap Partition
- **Size**: 8GB (or 2x RAM for hibernation)
- **Type**: Linux swap
- **Purpose**: Virtual memory and hibernation
- **Priority**: 1 (highest)

### 5. Home Partition (/home)
- **Size**: Remaining disk space
- **Filesystem**: Btrfs with subvolumes
- **Purpose**: User data and personal files
- **Features**: Quotas, snapshots, compression

#### Btrfs Subvolume Layout for Home:
```
/dev/sda5 (btrfs volume)
├── @home         -> /home       (user home directories)
├── @home-snapshots -> /home/.snapshots (user data snapshots)
└── @shared       -> /home/shared (shared user data)
```

## Storage Management Features

### 1. OverlayFS for Immutable Root
KawaiiSec OS can be configured with an immutable root filesystem using OverlayFS:

- **Lower Layer**: Read-only base system
- **Upper Layer**: Writable overlay for changes
- **Work Directory**: OverlayFS working directory
- **Merged View**: Combined filesystem presented to users

Benefits:
- System integrity protection
- Easy rollback to clean state
- Reduced wear on storage devices
- Consistent lab environments

### 2. Btrfs Snapshots
Automatic snapshot management for system and user data:

- **Root Snapshots**: Taken before system updates
- **Home Snapshots**: Daily user data protection
- **Retention Policy**: Keep last 7 snapshots
- **Storage Efficiency**: Copy-on-write, minimal space usage

### 3. Disk Quotas
User and group quotas on `/home` partition:

- **Default User Quota**: 5GB soft, 6GB hard
- **Grace Period**: 7 days for soft limit
- **Group Quotas**: Available for shared projects
- **Monitoring**: Automated quota usage reports

### 4. Automated Cleanup
Scheduled maintenance tasks:

- **Temporary Files**: Clean `/tmp` daily
- **Package Cache**: Clean APT cache weekly
- **Log Files**: Rotate and compress system logs
- **Old Snapshots**: Remove snapshots older than 7 days

## Installation Instructions

### Using the KawaiiSec Installer

1. **Boot from installation media**
2. **Select "Advanced Partitioning"**
3. **Choose partition layout**:
   - Automatic (recommended)
   - Manual (for custom configurations)
4. **Configure storage features**:
   - Enable OverlayFS (optional)
   - Set up Btrfs snapshots
   - Configure disk quotas
5. **Complete installation**

### Manual Partitioning

If you prefer manual partitioning, use these commands:

```bash
# Create partition table
parted /dev/sda mklabel gpt

# Create EFI system partition
parted /dev/sda mkpart ESP fat32 1MiB 513MiB
parted /dev/sda set 1 esp on

# Create boot partition
parted /dev/sda mkpart primary ext4 513MiB 1537MiB

# Create root partition
parted /dev/sda mkpart primary btrfs 1537MiB 33537MiB

# Create swap partition
parted /dev/sda mkpart primary linux-swap 33537MiB 41537MiB

# Create home partition
parted /dev/sda mkpart primary btrfs 41537MiB 100%

# Format partitions
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.btrfs -L kawaiisec-root /dev/sda3
mkswap /dev/sda4
mkfs.btrfs -L kawaiisec-home /dev/sda5

# Create Btrfs subvolumes
mount /dev/sda3 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@opt
umount /mnt

mount /dev/sda5 /mnt
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@home-snapshots
btrfs subvolume create /mnt/@shared
umount /mnt
```

## Performance Considerations

### SSD Optimizations
For systems with SSD storage:

- **Enable TRIM**: `fstrim.timer` systemd service
- **Reduce Write Amplification**: Use appropriate mount options
- **Align Partitions**: Start partitions on 1MiB boundaries

### HDD Optimizations
For traditional hard drives:

- **Minimize Seeks**: Group frequently accessed data
- **Enable Readahead**: Optimize for sequential access
- **Use Compression**: Reduce I/O with Btrfs compression

## Troubleshooting

### Common Issues

1. **Boot Problems**
   - Check EFI system partition is properly mounted
   - Verify GRUB configuration
   - Ensure secure boot compatibility

2. **Snapshot Issues**
   - Check available disk space
   - Verify Btrfs health: `btrfs filesystem show`
   - Clear old snapshots if needed

3. **Quota Problems**
   - Ensure quotas are enabled in `/etc/fstab`
   - Run `quotacheck` to rebuild quota files
   - Check quota limits with `quota -u username`

### Recovery Procedures

If the system becomes unbootable:

1. **Boot from Live USB**
2. **Mount root filesystem**:
   ```bash
   mount -o subvol=@ /dev/sda3 /mnt
   mount /dev/sda2 /mnt/boot
   mount /dev/sda1 /mnt/boot/efi
   ```
3. **Chroot into system**: `chroot /mnt`
4. **Repair or restore from snapshot**

## Security Considerations

### File System Security
- **Mount Options**: Use `noexec`, `nosuid`, `nodev` where appropriate
- **Encryption**: Consider LUKS encryption for sensitive data
- **Permissions**: Strict permissions on system directories

### Access Control
- **User Quotas**: Prevent disk space exhaustion attacks
- **Immutable Root**: Protect against unauthorized system changes
- **Audit Trail**: Log all file system modifications

## Advanced Configurations

### RAID Setup
For redundancy with multiple disks:

```bash
# Create Btrfs RAID1 for critical data
mkfs.btrfs -d raid1 -m raid1 /dev/sdb /dev/sdc
```

### Encryption
Full disk encryption setup:

```bash
# Encrypt home partition
cryptsetup luksFormat /dev/sda5
cryptsetup luksOpen /dev/sda5 kawaiisec-home
mkfs.btrfs /dev/mapper/kawaiisec-home
```

### Network Storage
Integration with network storage:

- **NFS**: For shared lab environments
- **iSCSI**: For high-performance storage
- **CIFS/SMB**: For Windows integration

## Maintenance

### Regular Tasks
- **Weekly**: Check disk usage and quota status
- **Monthly**: Verify Btrfs filesystem integrity
- **Quarterly**: Review partition layout for optimization

### Monitoring
- **Disk Space**: Alert when partitions exceed 80% usage
- **Snapshot Storage**: Monitor snapshot storage consumption
- **I/O Performance**: Track disk performance metrics

---

*This documentation is part of the KawaiiSec OS project. For updates and support, visit our GitHub repository.* 