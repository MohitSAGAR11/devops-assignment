# Linux Assignment

Practiced on Ubuntu (WSL2). Each task has one shell script; all four were run and verified.

```bash
chmod +x *.sh
sudo ./task1_links.sh
sudo ./task2_adduser_vs_useradd.sh
sudo ./task3_journalctl.sh          # optional: ./task3_journalctl.sh ssh
./task4_cheatsheet.sh
```

---

## Task 1 - Soft Link & Hard Link  → `task1_links.sh`  ✅ done

| | Hard link | Soft link (symlink) |
|---|---|---|
| Create | `ln file link` | `ln -s file link` |
| Points to | the **inode** (data) | the **path/name** |
| Inode | same as original | its own inode |
| Delete original | link still works | link becomes **broken/dangling** |
| Directories | not allowed | allowed |
| Across filesystems | not allowed | allowed |
| `ls -l` type | `-` (normal file) | `l`, shows `link -> target` |
| Size | same as file | length of the target path |

Delete: `rm link` or `unlink link` (never `rm dirlink/` — the trailing slash follows into the directory).

Verified in the script:
- `ls -li` showed `original.txt` and `hardlink.txt` sharing inode `18003` with link count `2`; the symlink had its own inode `19059`.
- After `rm original.txt`: `cat hardlink.txt` still printed the data, `cat softlink.txt` → `No such file or directory`.
- `ln realdir dirhard` → `hard link not allowed for directory`.
- `ln /tmp/... /mnt/c/...` → `Invalid cross-device link`; the same as a symlink worked.
- Deleting the symlink left `realdir` untouched.

Extras: `readlink -f link` resolves the full path, `find . -xtype l` lists broken symlinks.

**Interview answer (short):** a hard link is a second name for the same inode, so the file's data lives until the last name is removed; a soft link is a small separate file holding a path, so it breaks if the target is renamed or deleted, but it can cross filesystems and point at directories.

---

## Task 2 - `adduser` vs `useradd`  → `task2_adduser_vs_useradd.sh`  ✅ done

- `useradd` — low-level **binary** (shadow-utils), same on every distro. Creates only the bare account: no home directory, shell defaults to `/bin/sh`. Needs flags: `useradd -m -s /bin/bash -G sudo bob`.
- `adduser` — high-level **Perl script** (Debian/Ubuntu only) that calls `useradd` for you. Interactive, reads `/etc/adduser.conf`, creates the home directory, copies `/etc/skel`, creates the matching group, and prompts for the password.

**Preferred on Ubuntu: `adduser`** — it applies the distro's policy and gives a usable account in one step; `useradd` is the portable/scriptable one.

Test user created with the recommended command:
```bash
sudo adduser testuser          # script uses --gecos "" --disabled-password to stay non-interactive
```
Verified: `uid=1000(testuser) gid=1000(testuser) groups=1000(testuser),100(users)`, home `/home/testuser` with `.bashrc .profile .bash_logout` copied from `/etc/skel`, shell `/bin/bash`.

Contrast run in the same script: plain `useradd rawuser` gave shell `/bin/sh` and **no** `/home/rawuser`.

Cleanup: `sudo deluser --remove-home testuser` (or `sudo userdel -r testuser`).

---

## Task 3 - `journalctl`  → `task3_journalctl.sh`  ✅ done

`journalctl` reads the **systemd journal** — the binary, indexed log that `systemd-journald` collects from the kernel, services, and syslog. Replaces hunting through `/var/log/*`.

Commands practiced:

| Command | Purpose |
|---|---|
| `journalctl` | whole journal (oldest first) |
| `journalctl -n 20` | last 20 lines |
| `journalctl -u ssh` | **logs for one service** |
| `journalctl -u ssh -f` | follow live, like `tail -f` |
| `journalctl -b` / `--list-boots` | current boot / list previous boots |
| `journalctl -b -1` | previous boot (why did it crash) |
| `journalctl -p err` | priority error and worse (`emerg…debug`) |
| `journalctl --since "1 hour ago" --until now` | time window |
| `journalctl -k` | kernel messages only (`dmesg`) |
| `journalctl --disk-usage` | how much space the journal uses |
| `journalctl --vacuum-time=7d` | trim old logs |
| `-o json-pretty` / `--no-pager` | output formats |

Verified: `journalctl -u systemd-journald` returned real entries; `--list-boots` listed 12 boots; `-p err` surfaced kernel `dxgk` errors. Everyday debug combo: `journalctl -u <service> -b -p err --since "10 min ago"`.

Note: needs root, or membership of `adm` / `systemd-journal`, to see other users' logs.

---

## Task 4 - Linux Command Cheat Sheet  → `task4_cheatsheet.sh`  ✅ done

Script runs every command live in `/tmp/cheat-lab`, grouped by area:

- **Navigation** — `pwd cd ls -la ls -lh mkdir -p tree find`
- **Files** — `touch cp mv rm rm -rf`
- **Viewing** — `cat head tail wc less/more`
- **Search** — `grep -n -c find -name -type -size`
- **Text / pipes** — `| > >> 2>/dev/null sort uniq tr cut paste awk sed`
- **Permissions** — `chmod 644/600/+x chown stat -c '%a' umask`
- **Identity** — `whoami id groups`
- **Processes** — `ps aux top kill kill -9 & jobs fg bg`
- **Disk / memory** — `df -h du -sh free -h uptime`
- **System** — `uname -a hostname date /etc/os-release`
- **Network** — `ip a ip route ss -tuln ping curl dig`
- **Archive** — `tar -czf / -tzf / -xzf gzip gunzip`
- **Packages** — `apt update/install/remove/search dpkg -l`
- **Services** — `systemctl start|stop|restart|status|enable|disable`
- **Help** — `man --help which whatis type history`

Ran end to end with no errors.
