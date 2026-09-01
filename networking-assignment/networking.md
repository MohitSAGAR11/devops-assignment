# Networking Assignment

Commands practised from the **devops-heros** repo - `session4-networking/`
(`ip.md`, `resources.md`) and `session2-linux/Linux Networking Cheat Sheet.pdf`.

Everything below was executed on **Ubuntu (WSL2)**; the outputs are the real
output of those runs. `networking.sh` reproduces all of it and `output.log`
holds the raw log.

---

## Task 1 - Theory from `session4-networking/ip.md`

An **IP address** is the unique identifier of a device on a network. IPv4 is
32 bits, written as four octets (`0.0.0.0` - `255.255.255.255`).

**Classes (by first octet):**

| Class | First octet | Default mask | Network bits | Host bits | Usable hosts |
|---|---|---|---|---|---|
| A | 1 - 127   | 255.0.0.0     | 8  | 24 | 2^24 - 2 = 16,777,214 |
| B | 128 - 191 | 255.255.0.0   | 16 | 16 | 2^16 - 2 = 65,534 |
| C | 192 - 223 | 255.255.255.0 | 24 | 8  | 2^8 - 2 = 254 |
| D | 224 - 239 | multicast     | -  | -  | - |

The **subnet mask** splits an address into the *network part* and the *host
part*. Two addresses are always reserved - the network address (all host bits
0) and the broadcast address (all host bits 1) - which is where the `-2` comes
from.

Worked examples from the notes:

- `197.23.45.10` with mask `255.255.255.0` -> Class C, network `197.23.45.0`,
  broadcast `197.23.45.255`, 254 usable hosts.
- `120.27.1.0/8` -> Class A, 8 network bits, 24 host bits, broadcast
  `120.255.255.255`.

**Private ranges** (never routed on the internet):
`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.

My own machine confirms this - `ip addr` below shows `172.30.207.24/20`, a
private address, while `curl ifconfig.me` shows the very different public IP
the internet actually sees.

---

## Task 2 - Commands, output and what I understood

### 1. `ip addr` - show IP addresses

```bash
ip addr
ip -br addr
```

<details><summary>output</summary>

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet 10.255.255.254/32 brd 10.255.255.254 scope global lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:40:75:a6 brd ff:ff:ff:ff:ff:ff
    inet 172.30.207.24/20 brd 172.30.207.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::215:5dff:fe40:75a6/64 scope link 
       valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 5a:c4:e7:69:6d:5a brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
--- short form ---
lo               UNKNOWN        127.0.0.1/8 10.255.255.254/32 ::1/128 
eth0             UP             172.30.207.24/20 fe80::215:5dff:fe40:75a6/64 
docker0          DOWN           172.17.0.1/16 
```

</details>

**Understood:** lists every interface with its IP. `lo` (127.0.0.1) is the
loopback - the machine talking to itself. `eth0` has `172.30.207.24/20`, the
real working address, where `/20` means 20 network bits. `docker0` is the
bridge Docker creates, `DOWN` because no container is running. `-br` prints the
same information as one tidy line per interface.

### 2. `ip link` - interfaces at layer 2

```bash
ip link
ip -s link
```

<details><summary>output</summary>

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether 00:15:5d:40:75:a6 brd ff:ff:ff:ff:ff:ff
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
    link/ether 5a:c4:e7:69:6d:5a brd ff:ff:ff:ff:ff:ff
--- interface statistics ---
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    RX:  bytes packets errors dropped  missed   mcast           
         17978     126      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
         17978     126      0       0       0       0 
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether 00:15:5d:40:75:a6 brd ff:ff:ff:ff:ff:ff
    RX:  bytes packets errors dropped  missed   mcast           
      43876921   29106      0       0       0       8 
    TX:  bytes packets errors dropped carrier collsns           
        301297    3667      0       0       0       0 
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
    link/ether 5a:c4:e7:69:6d:5a brd ff:ff:ff:ff:ff:ff
    RX:  bytes packets errors dropped  missed   mcast           
             0       0      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
             0       0      0       2       0       0 
```

</details>

**Understood:** `ip addr` is about IP (layer 3), `ip link` is about the NIC
itself (layer 2) - MAC address, MTU and state. `<UP,LOWER_UP>` means the
interface is enabled *and* the carrier is present. `ip -s link` adds RX/TX
counters, the first place to look for `errors` or `dropped` packets when a link
misbehaves.

### 3. `ip route` - the routing table

```bash
ip route
ip route get 8.8.8.8
```

<details><summary>output</summary>

```
default via 172.30.192.1 dev eth0 proto kernel 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
172.30.192.0/20 dev eth0 proto kernel scope link src 172.30.207.24 
--- which route would a packet to 8.8.8.8 take? ---
8.8.8.8 via 172.30.192.1 dev eth0 src 172.30.207.24 uid 0 
    cache 
```

</details>

**Understood:** the kernel's map of "to reach network X, send it out of
interface Y". The `default via 172.30.192.1 dev eth0` line is the **default
gateway** - anything without a more specific route goes there. `ip route get`
is the useful debugging one: it asks the kernel which route a real packet would
actually take instead of making me read the table myself.

### 4. `ip neigh` - the ARP table

```bash
ip neigh
ip -s neigh
```

<details><summary>output</summary>

```
172.30.192.1 dev eth0 lladdr 00:15:5d:72:7a:68 DELAY 
--- with stats ---
172.30.192.1 dev eth0 lladdr 00:15:5d:72:7a:68  ref 1 used 2/108/2probes 4 DELAY 
```

</details>

**Understood:** ARP maps an IP address to a MAC address on the local network,
because a frame is delivered to a MAC, not to an IP. The entry here is the
gateway. `REACHABLE` means the mapping was recently confirmed; entries can also
be `STALE` or `FAILED`. Old equivalent: `arp -a`.

### 5. `ip maddr` - multicast addresses

```bash
ip maddr
```

<details><summary>output</summary>

```
1:	lo
	inet  224.0.0.1
	inet6 ff02::1
	inet6 ff01::1
2:	eth0
	link  33:33:00:00:00:01
	link  01:00:5e:00:00:01
	link  33:33:ff:40:75:a6
	inet  224.0.0.1
	inet6 ff02::1:ff40:75a6
	inet6 ff02::1
	inet6 ff01::1
3:	docker0
	link  33:33:00:00:00:01
	link  01:00:5e:00:00:6a
```

</details>

**Understood:** multicast is one-to-many delivery. `224.0.0.1` is the "all
hosts on this subnet" group and `ff02::1` is its IPv6 equivalent. This lists
the groups each interface is listening to.

### 6. `hostname`

```bash
hostname
hostname -I
hostname -f
```

<details><summary>output</summary>

```
LAPTOP-RUQ5M8OH
172.30.207.24 172.17.0.1 
LAPTOP-RUQ5M8OH.localdomain
```

</details>

**Understood:** `hostname` prints the machine name, `-I` prints only the IP
addresses (handy in scripts), `-f` prints the fully-qualified domain name.

### 7. `ping` - is the host reachable?

```bash
ping -c 3 127.0.0.1
ping -c 3 8.8.8.8
```

<details><summary>output</summary>

```
PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.034 ms
64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.028 ms
64 bytes from 127.0.0.1: icmp_seq=3 ttl=64 time=0.039 ms

--- 127.0.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2035ms
rtt min/avg/max/mdev = 0.028/0.033/0.039/0.004 ms
--- external host ---
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=119 time=16.2 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=119 time=15.2 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=119 time=16.8 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2006ms
rtt min/avg/max/mdev = 15.238/16.050/16.758/0.624 ms
```

</details>

**Understood:** sends ICMP echo requests and waits for replies. It answers two
questions: *is it reachable* (0% packet loss) and *how far / how slow* (~18 ms
to 8.8.8.8 against 0.03 ms to loopback). `ttl=119` means the reply started at
TTL 128 and nine hops decremented it. Loss or a large `mdev` points at a flaky
link. A failed ping does not always mean "down" - plenty of hosts simply drop
ICMP.

### 8. `traceroute` - the path a packet takes

```bash
traceroute -m 8 -w 1 8.8.8.8
```

<details><summary>output</summary>

```
traceroute to 8.8.8.8 (8.8.8.8), 8 hops max, 60 byte packets
 1  LAPTOP-RUQ5M8OH.mshome.net (172.30.192.1)  0.669 ms  0.647 ms  0.638 ms
 2  wifi.height8tech.com (100.128.160.1)  57.941 ms  31.610 ms  31.603 ms
 3  114.79.130.29.dvois.com (114.79.130.29)  61.424 ms  61.417 ms  61.411 ms
 4  72.14.208.165 (72.14.208.165)  61.395 ms  61.389 ms  61.382 ms
 5  192.178.111.151 (192.178.111.151)  31.594 ms  57.840 ms 192.178.84.175 (192.178.84.175)  57.916 ms
 6  142.251.64.11 (142.251.64.11)  57.827 ms 74.125.253.167 (74.125.253.167)  51.830 ms 142.250.208.221 (142.250.208.221)  51.689 ms
 7  dns.google (8.8.8.8)  51.684 ms  37.612 ms  37.593 ms
```

</details>

**Understood:** sends packets with an increasing TTL so each router along the
way is forced to reply, which reveals the hops. Hop 1 is my gateway, hops 2-3
are my ISP (`dvois.com`), then Google's network, then `dns.google` itself. This
is how you find *where* traffic dies - if ping fails, traceroute shows the hop
it stopped at.

### 9. DNS lookups - `dig`, `nslookup`, `host`

```bash
dig google.com +short
dig google.com A +noall +answer
nslookup google.com
host google.com
dig -x 8.8.8.8 +short
```

<details><summary>output</summary>

```
--- dig ---
142.250.206.110
--- dig A record, short answer section ---
google.com.		7	IN	A	142.250.206.110
--- nslookup ---
Server:		10.255.255.254
Address:	10.255.255.254#53

Non-authoritative answer:
Name:	google.com
Address: 142.250.206.110
Name:	google.com
Address: 2404:6800:4009:81f::200e

--- host ---
google.com has address 142.250.206.110
google.com has IPv6 address 2404:6800:4009:81f::200e
google.com mail is handled by 10 smtp.google.com.
--- reverse lookup ---
dns.google.
```

</details>

**Understood:** DNS turns a name into an IP. `dig +short` gives just the
answer; the full form shows the record type (`A` = IPv4, `AAAA` = IPv6,
`MX` = mail) and the **TTL**, i.e. how many seconds the answer may be cached.
`nslookup` also prints which DNS server answered. `dig -x` does the reverse
lookup (IP -> name) and correctly returned `dns.google`. When a site "does not
work", this is what separates a DNS problem from a connectivity problem.

### 10. `/etc/resolv.conf` and `/etc/hosts`

```bash
cat /etc/resolv.conf
cat /etc/hosts
```

<details><summary>output</summary>

```
--- /etc/resolv.conf (which DNS server we use) ---
# This file was automatically generated by WSL. To stop automatic generation of this file, add the following entry to /etc/wsl.conf:
# [network]
# generateResolvConf = false
nameserver 10.255.255.254
--- /etc/hosts (static name -> IP map) ---
# This file was automatically generated by WSL. To stop automatic generation of this file, add the following entry to /etc/wsl.conf:
# [network]
# generateHosts = false
127.0.0.1	localhost
127.0.1.1	LAPTOP-RUQ5M8OH.localdomain	LAPTOP-RUQ5M8OH

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

</details>

**Understood:** `/etc/resolv.conf` holds the `nameserver` the resolver queries.
`/etc/hosts` is a static name-to-IP file checked **before** DNS, which makes it
the quickest way to override a hostname for testing.

### 11. `ss` - socket statistics

```bash
ss -tulnp
ss -s
```

<details><summary>output</summary>

```
--- listening TCP+UDP with ports, numeric, with process ---
Netid State  Recv-Q Send-Q  Local Address:Port  Peer Address:PortProcess                                                                                                                                                                                                                                                                                                            
udp   UNCONN 0      0          127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=212,fd=16))                                                                                                                                                                                                                                                                         
udp   UNCONN 0      0       127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=212,fd=14))                                                                                                                                                                                                                                                                         
udp   UNCONN 0      0      10.255.255.254:53         0.0.0.0:*                                                                                                                                                                                                                                                                                                                      
udp   UNCONN 0      0             0.0.0.0:111        0.0.0.0:*    users:(("rpcbind",pid=211,fd=5),("systemd",pid=1,fd=33))                                                                                                                                                                                                                                                          
udp   UNCONN 0      0           127.0.0.1:323        0.0.0.0:*                                                                                                                                                                                                                                                                                                                      
udp   UNCONN 0      0                [::]:111           [::]:*    users:(("rpcbind",pid=211,fd=7),("systemd",pid=1,fd=35))                                                                                                                                                                                                                                                          
udp   UNCONN 0      0               [::1]:323           [::]:*                                                                                                                                                                                                                                                                                                                      
tcp   LISTEN 0      4096        127.0.0.1:43979      0.0.0.0:*    users:(("containerd",pid=283,fd=15))                                                                                                                                                                                                                                                                              
tcp   LISTEN 0      4096          0.0.0.0:111        0.0.0.0:*    users:(("rpcbind",pid=211,fd=4),("systemd",pid=1,fd=32))                                                                                                                                                                                                                                                          
tcp   LISTEN 0      511           0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=276,fd=5),("nginx",pid=275,fd=5),("nginx",pid=274,fd=5),("nginx",pid=273,fd=5),("nginx",pid=272,fd=5),("nginx",pid=271,fd=5),("nginx",pid=270,fd=5),("nginx",pid=269,fd=5),("nginx",pid=268,fd=5),("nginx",pid=266,fd=5),("nginx",pid=265,fd=5),("nginx",pid=264,fd=5),("nginx",pid=261,fd=5))
tcp   LISTEN 0      4096    127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=212,fd=15))                                                                                                                                                                                                                                                                         
tcp   LISTEN 0      4096       127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=212,fd=17))                                                                                                                                                                                                                                                                         
tcp   LISTEN 0      1000   10.255.255.254:53         0.0.0.0:*                                                                                                                                                                                                                                                                                                                      
tcp   LISTEN 0      4096             [::]:111           [::]:*    users:(("rpcbind",pid=211,fd=6),("systemd",pid=1,fd=34))                                                                                                                                                                                                                                                          
tcp   LISTEN 0      511              [::]:80            [::]:*    users:(("nginx",pid=276,fd=6),("nginx",pid=275,fd=6),("nginx",pid=274,fd=6),("nginx",pid=273,fd=6),("nginx",pid=272,fd=6),("nginx",pid=271,fd=6),("nginx",pid=270,fd=6),("nginx",pid=269,fd=6),("nginx",pid=268,fd=6),("nginx",pid=266,fd=6),("nginx",pid=265,fd=6),("nginx",pid=264,fd=6),("nginx",pid=261,fd=6))
--- summary ---
Total: 264
TCP:   8 (estab 0, closed 0, orphaned 0, timewait 0)

Transport Total     IP        IPv6
RAW	  0         0         0        
UDP	  7         5         2        
TCP	  8         6         2        
INET	  15        11        4        
FRAG	  0         0         0        
```

</details>

**Understood:** shows which ports are open and who owns them. `-t` TCP,
`-u` UDP, `-l` listening only, `-n` numeric (no DNS lookups, so it is fast),
`-p` the owning process. Here nginx is listening on `0.0.0.0:80` and
`systemd-resolve` on `:53`. `0.0.0.0` means "on every interface" while
`127.0.0.1` means local-only. This is the go-to for "is my service actually
listening, and on the right interface?" and for finding port conflicts.

### 12. `curl` / `wget` - talk HTTP

```bash
curl -s -I https://example.com
curl -s -o /dev/null -w "HTTP status: %{http_code}\n" https://example.com
curl -s https://ifconfig.me
```

<details><summary>output</summary>

```
--- headers only ---
HTTP/2 200 
date: Tue, 01 Sep 2026 05:16:39 GMT
content-type: text/html
server: cloudflare
last-modified: Sun, 30 Aug 2026 04:11:49 GMT
allow: GET, HEAD
accept-ranges: bytes
age: 1625
cf-cache-status: HIT
cf-ray: a341cddbdf542b14-BOM

--- status code only ---
HTTP status: 200
--- my public IP ---
202.131.143.43
```

</details>

**Understood:** `curl -I` fetches only the response headers, which is enough to
see the status line and which server answered. The `-w "%{http_code}"` form is
what scripts and health checks use. `curl ifconfig.me` returned
`202.131.143.43`, my **public** IP - different from the private
`172.30.207.24` on the interface, which is exactly what NAT does.

### 13. `nc` (netcat) - is a TCP port open?

```bash
nc -zv -w 3 google.com 443
nc -zv -w 3 google.com 9999
```

<details><summary>output</summary>

```
Connection to google.com (142.250.206.110) 443 port [tcp/https] succeeded!
nc: connect to google.com (142.250.206.110) port 9999 (tcp) timed out: Operation now in progress
nc: connect to google.com (2404:6800:4009:81f::200e) port 9999 (tcp) failed: Network is unreachable
```

</details>

**Understood:** `-z` tests the connection without sending data and `-v` makes
it report the result. Port 443 succeeded, port 9999 timed out. Unlike ping this
tests a *specific port*, which is the usual way to prove a firewall or security
group is blocking you rather than the host being down.

### 14. `ethtool` - NIC driver and hardware

```bash
ethtool -i eth0
```

<details><summary>output</summary>

```
default interface: eth0
driver: hv_netvsc
version: 6.18.33.2-microsoft-standard-WS
firmware-version: N/A
expansion-rom-version: 
bus-info: 2b133adf-e817-4770-85d1-b3f7497
supports-statistics: yes
supports-test: no
supports-eeprom-access: no
```

</details>

**Understood:** reports the driver behind the interface - `hv_netvsc`, the
Hyper-V virtual NIC, because this is WSL. On physical servers it also shows
link speed and duplex, ring buffers (`ethtool -g`) and per-NIC error counters
(`ethtool -S`).

### 15. net-tools (old) vs iproute2 (new)

```bash
ifconfig -a      # == ip addr
route -n         # == ip route
arp -a           # == ip neigh
netstat -tuln    # == ss -tuln
```

<details><summary>output</summary>

```
--- ifconfig -a   ==  ip addr ---
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 172.17.255.255
        ether 5a:c4:e7:69:6d:5a  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 2 overruns 0  carrier 0  collisions 0

eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.30.207.24  netmask 255.255.240.0  broadcast 172.30.207.255
        inet6 fe80::215:5dff:fe40:75a6  prefixlen 64  scopeid 0x20<link>
        ether 00:15:5d:40:75:a6  txqueuelen 1000  (Ethernet)
--- route -n      ==  ip route ---
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.30.192.1    0.0.0.0         UG    0      0        0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
172.30.192.0    0.0.0.0         255.255.240.0   U     0      0        0 eth0
--- arp -a        ==  ip neigh ---
LAPTOP-RUQ5M8OH.mshome.net (172.30.192.1) at 00:15:5d:72:7a:68 [ether] on eth0
--- netstat -tuln ==  ss -tuln ---
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State      
tcp        0      0 127.0.0.1:43979         0.0.0.0:*               LISTEN     
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN     
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN     
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN     
tcp        0      0 127.0.0.54:53           0.0.0.0:*               LISTEN     
tcp        0      0 10.255.255.254:53       0.0.0.0:*               LISTEN     
tcp6       0      0 :::111                  :::*                    LISTEN     
tcp6       0      0 :::80                   :::*                    LISTEN     
```

</details>

**Understood:** the cheat sheet's comparison table, run side by side. The
`net-tools` commands are deprecated and usually absent from a modern minimal
image - I had to `apt install net-tools` to run these - so the `ip` / `ss`
versions are the ones worth knowing:

| net-tools | iproute2 |
|---|---|
| `ifconfig -a` | `ip addr` |
| `ifconfig eth0 up` / `down` | `ip link set eth0 up` / `down` |
| `ifconfig eth0 mtu 9000` | `ip link set eth0 mtu 9000` |
| `route` | `ip route` |
| `route add default gw 192.168.1.1` | `ip route add default via 192.168.1.1` |
| `arp -a` | `ip neigh` |
| `netstat -tuln` | `ss -tuln` |
| `netstat -g` | `ip maddr` |

### 16. The "modify" commands, practised safely on a dummy interface

```bash
ip link add lab0 type dummy            # fake NIC, nothing real is touched
ip addr add 192.168.100.1/24 dev lab0
ip link set lab0 up
ip link set lab0 mtu 1400
ip route add 10.99.0.0/24 dev lab0
ip neigh add 192.168.100.50 lladdr 02:00:00:00:00:01 dev lab0
# undo
ip neigh del 192.168.100.50 dev lab0
ip route del 10.99.0.0/24 dev lab0
ip addr del 192.168.100.1/24 dev lab0
ip link set lab0 down
ip link del lab0
```

<details><summary>output</summary>

```
lab0             UNKNOWN        192.168.100.1/24 fe80::cc49:7eff:fedc:b1dc/64 
5: lab0: <BROADCAST,NOARP,UP,LOWER_UP> mtu 1400 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether ce:49:7e:dc:b1:dc brd ff:ff:ff:ff:ff:ff
--- add a route through it ---
10.99.0.0/24 dev lab0 scope link 
--- add a static ARP entry ---
192.168.100.50 lladdr 02:00:00:00:00:01 PERMANENT 
--- now undo everything ---
lab0 removed:
Device "lab0" does not exist.
```

</details>

**Understood:** the cheat sheet's write commands (`addr add/del`,
`link set up/down/mtu`, `route add/delete`, `neigh add/del`) all worked, and
the `del` half put everything back - `lab0` no longer exists at the end.

I ran them on a **dummy** interface deliberately: `ip link set eth0 down` on
the real NIC would cut the connection, and on a remote server that means
locking yourself out. A dummy interface gives identical practice with no risk.
Also worth remembering that all of these are **runtime only** - they are lost
on reboot unless written into netplan / NetworkManager config.

---

## Quick reference

| Question | Command |
|---|---|
| What is my IP? | `ip addr` / `ip -br addr` / `hostname -I` |
| What is my public IP? | `curl ifconfig.me` |
| What is my gateway? | `ip route` |
| Which route will this packet take? | `ip route get 8.8.8.8` |
| Is the host up? | `ping -c 3 <host>` |
| Where does it break? | `traceroute <host>` |
| What is this name's IP? | `dig <name> +short` |
| Which ports are open here? | `ss -tulnp` |
| Is that port open there? | `nc -zv -w 3 <host> <port>` |
| Is the web service healthy? | `curl -I https://<host>` |
| IP to MAC on my LAN | `ip neigh` |

## Troubleshooting order I would follow

1. `ip addr` - do I even have an IP?
2. `ip route` - is there a default gateway?
3. `ping <gateway>` - can I reach my own LAN?
4. `ping 8.8.8.8` - is the internet reachable by IP?
5. `dig google.com` - if step 4 works but names fail, it is DNS.
6. `ss -tulnp` / `nc -zv host port` - is the service listening, is the port open?
