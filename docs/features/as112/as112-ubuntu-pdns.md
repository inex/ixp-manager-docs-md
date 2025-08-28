# Installing an AS112 Server on Ubuntu with PowerDNS

These instructions reflect live AS112 nodes at INEX in Dublin, Ireland. They also follow from the [Vagrant test-bed](../../dev/vagrant.md) we use for IXP Manager. At the time of writing, we are installing an AS112 node with:

* Ubuntu 24.04 LTS
* BIRD 2 (BGP daemon) with RPKI (if configured)
* PowerDNS


## Server Setup

Install a minimized (this is an option when using the standard installer) Ubuntu 24.04 server, and consider the following notes from our process:

1. Assuming you are installing on a virtual machine, we recommend you partition the hard drive with a 1Gb `/boot` partition and then use LVM for a `/` root partition and swap space. This will allow you to dynamically add more space should you need it. We installed a 30Gb hard drive to start.
2. Install the ssh server when prompted.
3. Do not install any additional packages during the installation (unless it is part of your standard install).
4. Complete the installation and reboot.

At this point, you should complete your standard server provisioning procedures. For example, we use SaltStack to create user accounts for our operations team, to set-up various utilities and daemons for standard monitoring, backups, etc., and to configure iptables.

### iptables and Connection Tracking

An an authoritative nameserver is generally going to accept all packets on 53/UDP from anywhere, you should disable connection tracking for udp DNS packets. You can do this with iptables per the following snippet:

```
*raw

# Don't track DNS
-A PREROUTING -p udp -m udp --dport 53 -j CT --notrack
-A PREROUTING -p udp -m udp --sport 53 -j CT --notrack
-A OUTPUT     -p udp -m udp --dport 53 -j CT --notrack
-A OUTPUT     -p udp -m udp --sport 53 -j CT --notrack

COMMIT

*filter
:INPUT DROP
:FORWARD DROP
:OUTPUT ACCEPT

-A INPUT   -m conntrack --ctstate ESTABLISHED,RELATED,UNTRACKED -j ACCEPT
-A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED,UNTRACKED -j ACCEPT

-A INPUT -p tcp -m tcp -m conntrack --ctstate NEW --dport 53 -j ACCEPT

...
COMMIT
```


## Network Configuration

Ubuntu is configured [via Netplan](https://netplan.readthedocs.io/en/latest/). 


### Basic Network Configuration

A sample `/etc/netplan/50-cloud-init.yaml` with an internal management IP and an external peering LAN IP might look like this:

```yaml
network:
  version: 2
  ethernets:
    enX0:
      addresses:
      - "192.0.2.7/24"
      - "2001:db8:18:9::7/64"
      routes:
      - to: "default"
        via: "192.0.2.1"
      - to: "default"
        via: "2001:db8:18:9::1"
      accept-ra: false
      ipv6-privacy: false
    enX1:
      addresses:
      - "198.51.100.6/24"
      - "2001:db8::6/64"
      accept-ra: false
      ipv6-privacy: false
```



### AS112 IP Addresses

AS112 uses a number of IP addresses to serve DNS requests. We need to assign these to the loopback interface by creating a dedicated netplan configuration file:


```sh
cat >/etc/netplan/70-as112.yaml <<END_YAML
##
## AS112 IP addresses - per https://datatracker.ietf.org/doc/html/rfc7534.html
##
## Configured from SaltStack - edits will be overwritten

network:
  version: 2
  renderer: networkd
  ethernets:
    lo:
      addresses:
        - "192.175.48.1/32"
        - "192.175.48.6/32"
        - "192.175.48.42/32"
        - "192.31.196.1/32"
        - "2620:4f:8000::1/128"
        - "2620:4f:8000::6/128"
        - "2620:4f:8000::42/128"
        - "2001:4:112::1/128"

END_YAML

chmod go-rwx /etc/netplan/70-as112.yaml
```

You can apply those IPs with:

```sh
netplan apply
```

And you can view, and test, them such as:

```sh
ip addr show dev lo

ping 192.31.196.1 # you're looking for a fraction of a ms response time!
```



### sysctl Settings for AS112

Because we will be generating a secure BGP configuration with RPKI, it is possible that some peers may learn our prefixes, but we will not learn theirs. In that event, responses will go via the default gateway, rather than the peering LAN. We may also have more than a single peering interface, which could provide multiple routes for the same prefix. To ensure responses are not blocked by the automatically-enabled reverse-path-filter, we disable it. We also enable ip routing and, in addition to the netplan file above, also disable various ipv6 autoconf settings by creating a sysctl file as follows:

```sh
cat >/etc/sysctl.d/999-as112.conf <<END_SYSCTL
# AS112 kernel settings

# Disable Source Address Verification in all interfaces 
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.all.rp_filter=0

net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

# Disable IPv6 Privacy Extensions (RFC 4941) 
net.ipv6.conf.all.use_tempaddr = 0
net.ipv6.conf.default.use_tempaddr = 0

net.ipv6.conf.default.router_solicitations = 0
net.ipv6.conf.default.accept_ra_rtr_pref = 0
net.ipv6.conf.default.accept_ra_pinfo = 0
net.ipv6.conf.default.accept_ra_defrtr = 0

net.ipv6.conf.default.accept_ra=0
net.ipv6.conf.all.accept_ra=0

net.ipv6.conf.default.max_addresses = 1

net.ipv6.conf.default.autoconf=0
net.ipv6.conf.all.autoconf=0

END_SYSCTL

sysctl --system
```


## PowerDNS

Install (and then stop) PowerDNS, with the bind backend and utilities, as follows:

```sh
apt install pdns-server pdns-backend-bind bzip2 dnsutils
systemctl stop pdns.service
```

We have published a production ready PowerDNS configuration file, with bind-backend configuration file, and all the zone files at the following locations:

* [https://github.com/inex/IXP-Manager/tree/main/tools/runtime/as112/powerdns](https://github.com/inex/IXP-Manager/tree/main/tools/runtime/as112/powerdns)
* [https://github.com/inex/IXP-Manager/tree/main/tools/runtime/as112/zones](https://github.com/inex/IXP-Manager/tree/main/tools/runtime/as112/zones)

To simplify things, we have also tar'd these up, such that you can configure and start your as112 PowerDNS server as follows:

```sh
cd /etc
rm -rf powerdns
wget -O /tmp/powerdns.tar.bz2 https://raw.githubusercontent.com/inex/IXP-Manager/refs/heads/main/tools/runtime/as112/powerdns.tar.bz2
tar jxf /tmp/powerdns.tar.bz2
chown -R pdns: powerdns
systemctl start pdns.service
```

You can now test for a NXDOMAIN and TXT responses as follows:

```
dig -x 10.3.4.5 @192.175.48.6
dig txt hostname.as112.net @192.175.48.1
```


## BIRD BGP

We have detailed documentation on [configuration BIRD with IXP Manager in general](../routers.md) and on [AS112 specifically](../as112.md). As such, we will limit this to simply running through the process at a nuts-and-bolts level. We assume you have configured AS112 routers in IXP Manager with the handles `as112-ipv4` and `as112-ipv6` here.

While BIRD v2 is available as a standard package with Ubuntu, it is quite dated. Specifically, the package is 2.14 dating from Oct 2023 whereas, at time of writing, the latest available package is 2.17.1 from May 2025. BIRD / NIC.CZ make current packages available at [https://pkg.labs.nic.cz/doc/?project=bird](https://pkg.labs.nic.cz/doc/?project=bird). Following those instructions, we can install BIRD as follows:

```sh
apt-get update
apt-get -y install apt-transport-https ca-certificates wget
wget -O /usr/share/keyrings/cznic-labs-pkg.gpg https://pkg.labs.nic.cz/gpg
echo "deb [signed-by=/usr/share/keyrings/cznic-labs-pkg.gpg] https://pkg.labs.nic.cz/bird2 noble main" > /etc/apt/sources.list.d/cznic-labs-bird2.list 
apt-get update
apt-get install bird2
```

As we're going to manage BIRD's configuration from IXP Manager, we will disable the systemd daemon as follows:

```sh
systemctl stop bird.service
systemctl disable bird.service
```

We can now download IXP Manager's script for managing configurations as follows:

```sh
cd /usr/local/sbin
wget -O ixpm-reconfigure-as112-bird2.sh https://raw.githubusercontent.com/inex/IXP-Manager/refs/heads/main/tools/runtime/router-reconfigure-scripts/api-reconfigure-example-birdv2.sh
chmod a+x ixpm-reconfigure-as112-bird2.sh
```

Now edit `ixpm-reconfigure-as112-bird2.sh` and set the three variables at the start:

```sh
APIKEY="your-api-key"
URLROOT="https://ixp.example.com"
ALLOWED_HANDLES="as112-ipv4 as112-ipv6"
```

You can now use this script to download a configuration, and start BIRD for our two AS112 instances as follows:

```sh
/usr/local/sbin/ixpm-reconfigure-as112-bird2.sh -h as112-ipv4
/usr/local/sbin/ixpm-reconfigure-as112-bird2.sh -h as112-ipv6
```

If you are not running this with IXP Manager, and would like to see what a sample BIRD2 configuration file looks like, please these samples which we use for continuous integration testing:

*
*


