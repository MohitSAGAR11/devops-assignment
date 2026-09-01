# Networking Assignment

| File | What it is |
|---|---|
| `networking.md` | **The submission** - every command with its real output and my explanation |
| `networking.sh` | The script that runs all of it (`sudo ./networking.sh`) |
| `output.log` | Raw captured output of the run |

**Task 1** - practised the commands from the devops-heros repo:
`session4-networking/ip.md` (IP classes, subnet masks, private ranges) and
`session2-linux/Linux Networking Cheat Sheet.pdf` (the `ip` subcommands plus
the net-tools vs iproute2 table). The theory notes are at the top of
`networking.md`.

**Task 2** - `networking.md` holds 16 sections: `ip addr`, `ip link`,
`ip route`, `ip neigh`, `ip maddr`, `hostname`, `ping`, `traceroute`,
`dig`/`nslookup`/`host`, `/etc/resolv.conf` + `/etc/hosts`, `ss`, `curl`,
`nc`, `ethtool`, the net-tools vs iproute2 comparison, and the `ip ... add/del`
write commands practised on a throwaway dummy interface. Each one has the
command, its output, and a short "what I understood" note.

Run on Ubuntu (WSL2). `net-tools` was installed for section 15
(`sudo apt install net-tools`).
