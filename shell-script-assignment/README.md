# Shell Scripting Assignment - System Information Script

`sysinfo.sh` prints the date, hostname, username, disk usage and running
processes, asks the user for a directory and file name, creates both, and
saves the full process list into that file using `>` redirection.

## How to run

```bash
chmod +x sysinfo.sh
./sysinfo.sh
```

## Requirements covered

| Requirement | Where in the script |
|---|---|
| Print current date | `CURRENT_DATE=$(date)` then `echo "Date : $CURRENT_DATE"` |
| Print hostname | `HOST_NAME=$(hostname)` |
| Print username | `USER_NAME=$(whoami)` |
| Print disk usage | `DISK_USAGE=$(df -h)` |
| Print running processes | `ps aux \| head -10` |
| Use variables | `CURRENT_DATE`, `HOST_NAME`, `USER_NAME`, `DISK_USAGE`, `DIR_NAME`, `FILE_NAME` |
| Take user input | `read -p "Enter a directory name to create : " DIR_NAME` |
| Create directory | `mkdir -p "$DIR_NAME"` |
| Create file | `touch "$DIR_NAME/$FILE_NAME"` |
| Store processes with `>` | `ps aux > "$DIR_NAME/$FILE_NAME"` |
| `echo` | used throughout for all printed output |

## Commands used

`date`, `hostname`, `whoami`, `df -h`, `ps aux`, `read -p`, `mkdir`, `touch`,
`echo`, `head`, `wc -l`, and `>` output redirection.

## Output

Run on Ubuntu (WSL2). Values typed at the two prompts: **`myinfo`** and
**`processes.txt`**.

```
$ ./sysinfo.sh
myinfo
processes.txt
==============================
     SYSTEM INFORMATION
==============================
Date      : Tue Sep  1 05:10:04 UTC 2026
Hostname  : LAPTOP-RUQ5M8OH
Username  : mohit

----- DISK USAGE (df -h) -----
Filesystem      Size  Used Avail Use% Mounted on
none            3.9G     0  3.9G   0% /usr/lib/modules/6.18.33.2-microsoft-standard-WSL2
none            3.9G  4.0K  3.9G   1% /mnt/wsl
drivers         803G  548G  255G  69% /usr/lib/wsl/drivers
/dev/sdd       1007G  4.7G  951G   1% /
none            3.9G   32K  3.9G   1% /mnt/wslg
none            3.9G     0  3.9G   0% /usr/lib/wsl/lib
rootfs          3.9G  2.8M  3.9G   1% /init
none            3.9G  956K  3.9G   1% /run
none            3.9G     0  3.9G   0% /run/lock
none            3.9G     0  3.9G   0% /run/shm
none            3.9G   68K  3.9G   1% /mnt/wslg/versions.txt
none            3.9G   68K  3.9G   1% /mnt/wslg/doc
C:\             803G  548G  255G  69% /mnt/c
snapfuse         74M   74M     0 100% /snap/core22/2411
snapfuse         74M   74M     0 100% /snap/core22/2437
snapfuse        4.7M  4.7M     0 100% /snap/network-manager/1020
snapfuse         49M   49M     0 100% /snap/snapd/26382
snapfuse         50M   50M     0 100% /snap/snapd/26865
snapfuse        4.7M  4.7M     0 100% /snap/network-manager/981
tmpfs           795M   20K  795M   1% /run/user/1002

----- RUNNING PROCESSES (ps aux | head) -----
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1 21.4  0.1  21880 13312 ?        Ss   05:10   0:00 /sbin/init
root           2  0.0  0.0   3180  2204 hvc0     Sl+  05:10   0:00 /init
root           6  0.0  0.0   3604  2412 hvc0     Sl+  05:10   0:00 plan9 --control-socket 7 --log-level 4 --server-fd 8 --pipe-fd 10 --log-truncate
root          56  8.9  0.2  42376 16676 ?        S<s  05:10   0:00 /usr/lib/systemd/systemd-journald
root         104  9.2  0.0  25284  6572 ?        Ss   05:10   0:00 /usr/lib/systemd/systemd-udevd
root         121  0.0  0.0 152944  1748 ?        Ssl  05:10   0:00 snapfuse /var/lib/snapd/snaps/core22_2411.snap /snap/core22/2411 -o ro,nodev,allow_other,suid
root         123  5.9  0.0 227708  7372 ?        Ssl  05:10   0:00 snapfuse /var/lib/snapd/snaps/network-manager_1020.snap /snap/network-manager/1020 -o ro,nodev,allow_other,suid
root         124 33.4  0.1 601528 12140 ?        Ssl  05:10   0:00 snapfuse /var/lib/snapd/snaps/core22_2437.snap /snap/core22/2437 -o ro,nodev,allow_other,suid
root         138  0.0  0.0 152944  1780 ?        Ssl  05:10   0:00 snapfuse /var/lib/snapd/snaps/snapd_26382.snap /snap/snapd/26382 -o ro,nodev,allow_other,suid

Enter a directory name to create : Enter a file name to create      : Directory created : myinfo
File created      : myinfo/processes.txt

Running processes saved to myinfo/processes.txt
Lines written     : 92

----- first 5 lines of myinfo/processes.txt -----
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1 21.3  0.1  21880 13312 ?        Ss   05:10   0:00 /sbin/init
root           2  0.0  0.0   3180  2204 hvc0     Sl+  05:10   0:00 /init
root           6  0.0  0.0   3604  2412 hvc0     Sl+  05:10   0:00 plan9 --control-socket 7 --log-level 4 --server-fd 8 --pipe-fd 10 --log-truncate
root          56  8.9  0.2  42376 16676 ?        S<s  05:10   0:00 /usr/lib/systemd/systemd-journald

Done.
```

## Result on disk

```
$ ls -lR
/tmp/sysrun:
total 4
drwxr-xr-x 2 mohit mohit 4096 Sep  1 05:10 myinfo

/tmp/sysrun/myinfo:
total 12
-rw-r--r-- 1 mohit mohit 9228 Sep  1 05:10 processes.txt
```

The directory and the file were created from the values typed at the `read -p`
prompts, and `ps aux > myinfo/processes.txt` wrote the full process list into
the file.
