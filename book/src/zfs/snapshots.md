# Snapshots

This will be a guide on how to leverage the features of ZFS and create snapshots of machines running ZFS.

We'll then send them to another machine also running ZFS to have a backup.

# Resources

- [ZFS Snapshot Briefer](https://www.howtoforge.com/tutorial/how-to-use-snapshots-clones-and-replication-in-zfs-on-linux)
- [Fast ZFS Send with Netcat](https://blog.yucas.net/2017/01/04/fast-zfs-send-with-netcat/)

# Requirements

- Two machines configured with ZFS
- If you want to browse the snapshots via SMB/NFS you'll need to create the share on TrueNAS. I made one called `zfs_snapshots`

I'll be using my laptop running `NixOS 24.05` with ZFS as the machine to backup. The backup server(target) will be a machine running `TrueNAS SCALE Dragonfish-24.04.2`

# How-To

1. View your zfs pools using `zpool list`

```bash
[troy@nixos:~]$ zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
zroot   228G  5.99G   222G        -         -     0%     2%  1.00x    ONLINE  -
```

2. We'll create a snapshot of the zroot dataset. `sudo zfs snapshot -r DATASET@NAME`. Note the `-r` flag. This will create a snapshot of the dataset and all of its children. We'll run this initially and every subsequent snapshot you can exlude this flag.

```bash
[troy@nixos:~]$ sudo zfs snapshot -r zroot@nixos_base
```

3. You can view the snapshots using `zfs list -t snapshot`

```bash
[troy@nixos:~]$ zfs list -t snapshot
NAME                    USED  AVAIL  REFER  MOUNTPOINT
zroot@nixos_base          0B      -    96K  -
zroot/root@nixos_base    56K      -  5.98G  -
```

4. On my TrueNAS system I'll do the same `zpool list`. We'll send the snapshot to `Pool0`
```bash
admin@truenas[~]$ sudo zpool list
NAME        SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
Pool0      2.72T   277G  2.45T        -         -     0%     9%  1.00x    ONLINE  /mnt
SSD0        111G  1.28M   111G        -         -     0%     0%  1.00x    ONLINE  /mnt
boot-pool   102G  2.41G  99.6G        -         -     0%     2%  1.00x    ONLINE  -
```

5. We're not gonna send it over SSH like usual. We'll use Netcat (`nc`). This is fine for a local network but you should use other methods if you're sending it over the internet.

    On TrueNAS we'll run the server with the following command.
    ```bash
    nc -w 120 -l -p 8023 | sudo zfs receive Pool0/zfs_snapshots/nixos_$(date +\%Y-\%m-\%d)
    ```
6. Now on our main machine we'll run the following. `sudo zfs send zroot/root@nixos_base | nc -w 20 192.168.1.9 8023`

7. After some time, the snapshot should be in the TrueNAS UI; But we can also view it from the command line.

```bash
admin@truenas[~]$ sudo zfs list -t snapshot
NAME                                              USED  AVAIL  REFER  MOUNTPOINT
Pool0@manual-2024-08-09_19-10                     133K      -   384K  -
Pool0@auto-2024-08-18_03-50                      95.9K      -   384K  -
Pool0@auto-2024-08-25_03-50                      95.9K      -   394K  -
Pool0@auto-2024-09-01_03-50                      95.9K      -   394K  -
Pool0/zfs_snapshots/nixos_2024-09-06@nixos_base   917M      -  9.73G  -
SSD0@manual-2024-08-09_19-10                        0B      -    96K  -
SSD0@auto-2024-08-18_03-50                          0B      -    96K  -
SSD0@auto-2024-08-25_03-50                          0B      -    96K  -
SSD0@auto-2024-09-01_03-50                          0B      -    96K  -
```