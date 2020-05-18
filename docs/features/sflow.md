# Introduction

IXP Manager can use [sflow](http://www.sflow.org/) data to:

- analyse BGP flows over the exchange and use the data to create a peering matrix
- build [peer-to-peer](sflow-p2p.md) traffic graphs

The peer-to-peer traffic graphs show traffic aggregate analysis of bytes/packets, split by VLAN and protocol (IPv4 / IPv6), both for individual IXP peering ports and entire VLANs.

# Helicopter View

Sflow needs to be configured with an "accounting perimeter".  This means that ingress sflow accounting should be enabled on all edge ports, but should not be enabled on any of the core ports.  This approach ensures that all packets entering or leaving the IXP are counted exactly once, when they enter the IXP fabric.

All the switches at the IXP should be configured to send sflow packets to the IP address of your sflow collector.  This will probably be the same server that you use for your IXP Manager sflow peer-to-peer graphing.

If sflow is enabled on any of the core ports or sflow is enabled in both directions (ingress + egress), traffic will be double-counted and this will lead to incorrect graphs.

Each switch on the network sends sampled sflow packets to an sflow collector.  These packets are processed by the "sflowtool" command, which converts into an easily-parseable ascii format.  IXP Manager provides a script to read the output of the sflowtool command, correlate this against the IXP database and to use this to build up a matrix of traffic flows which are then exported to an RRD database.

The RRD files are stored on disk and can be accessed by using the sflow graphing system included in IXP Manager.

# Sflow on Switches

Many vendors support sflow, but some do not.  There is a [partial list](http://www.sflow.org/products/network.php) on the sflow web site.

Most switches which support sflow will support ingress accounting, because this is what's required in [RFC 3176](http://www.ietf.org/rfc/rfc3176). Some switches (e.g. Dell Force10 running older software) only support egress sflow.  If you use these on your IXP alongside other switches which only support ingress sflow, then the sflow graphs will show twice the traffic in one direction for the p2p graphs and zero traffic in the other direction.  There is no way for IXP Manager to work around this problem.

If not all of the IXP edge ports are sflow capable, then sflow traffic data will be lost for these ports.  This means that some point-to-point traffic graphs will show up with zero traffic, and that the sflow aggregate graphs will be wrong.

Sflow uses data sampling.  This means that the results it produces are estimated projections, but on largee data sets, these projections tend to be statistically accurate.

Each switch or switch port needs to be configured with an sflow sampling rate. The exact rate chosen will depend on the traffic levels on the switch, how powerful the switch management plane CPU is, and how much bandwidth is available for the switch management.

On a small setup with low levels of traffic (e.g. 100kpps), it would be sensible to leave the sampling rate low (e.g. 1:1024). Alternatively, a busy 100G port may need a sampling rate of  1:32768 may turn out to be too low if the port is seeing large numbers of packets.  If the switch or the entire network is handling very large quantities of traffic, this figure should be high enough that IXP ports with low quantities of traffic will still get good quality graphs, but low enough that the switch management CPU isn't trashed, and that packets are not dropped on the management ethernet port.

Some switches have automatic rate-limiting built in for sflow data export.  The sampling rate needs to be chosen so that sflow data export rate limiting doesn't kick in.  If it does, samples will be lost and this will cause graph inaccuracies.

## Switch Implementation Limitations

### Netflow

IXP Manager does not support netflow and support is not on the roadmap. This is because most netflow implementations do not export mac address information, which means that they cannot provide workable mac layer peer-to-peer statistics.

### Cisco Switches

Of Cisco's entire product range, only the Nexus 3000 and Nexus 9000 product range support sflow. Also, the sflow support on the Cisco Nexus 3k range is crippled due to the NX-OS software implementation, which forces ingress+egress sflow to be configured on specified ports rather than ingress-only.  Functional accounting requires ingress-only or egress-only sflow to be configured on a per-port basis: ingress + egress causes double-counting of packets.  It may be possible to work around this limitation using the broadcom shell using something like the following untested configuration:

```
n3k# conf t
n3k(config)# feature sflow
n3k(config)# sflow data-source interface Ethernet1/1
n3k(config)# ^Z
n3k# test hardware internal bcm-usd bcm-diag-shell
Available Unit Numbers: 0
bcm-shell.0> PortSampRate xe0 4096 0
bcm-shell.0> PortSampRate xe0
 xe0:   ingress: 1 out of 4096 packets, egress: not sampling,
bcm-shell.0> quit
n3k#
```

Note that this command is not reboot persistent, and any time the switch is rebooted, the command needs to be re-entered manually.  Note also that this configuration is untested.

### Brocade TurboIron 24X

By default a TIX24X will export 100 sflow records per second.  This can be changed using the following command:

```
SSH@Switch# dm device-command 2762233
SSH@Switch# tor modreg CPUPKTMAXBUCKETCONFIG(3) PKT_MAX_REFRESH=0xHHHH
```

... where HHHH is the hex representation of the number of sflow records per second.  INEX has done some very primitive usage profiling which suggests that going above ~3000 sflow records per second will trash the management CPU too hard, so we use PKT_MAX_REFRESH=0x0BB8.  Note that this command is not reboot persistent, and any time a TIX24X is rebooted, the command needs to be re-entered manually.

### Dell Force10

Earlier versions of FTOS only support egress sflow, but support for ingress sflow was added in 2014.  If you intend to deploy IXP Manager sflow accounting on a Dell F10 switch, then you should upgrade to a software release which supports ingress sflow.

### Cumulus Linux

Cumulus Linux uses hsflowd, which does not allow the operator to enable or disable sflow on a per-port basis, nor does it permit the operator to configure ports to use ingress-only sflow.  This configuration needs to be handled using the `/usr/lib/cumulus/portsamp` command, which is not reboot persistent.  It is strongly recommended to handle this configuration using orchestration, as it is not feasible to manually maintain this configuration.

## Fanout

### Configuring sflowtool fan-out

The sflow data from all the IXP switches will normally be directed at a single sflow collector.  Often it is useful to have multiple copies of this sflow data stream so that the sflow data can be processed in different ways.

IXP Manager uses sflow data for two separate components:

1. point-to-point ixp traffic graphs
2. detecting BGP live sessions on the exchange and using the info to update the peering matrix

This means that IXP Manager needs two separate sflow feeds.  This can be achieved by using the `sflowtool` fanout facility, which sends an exact copy of all incoming sflow records to a list of destinations.  For example, the following command listens for incoming sflow data on port 6343 and send three copies out.  Two copies are directed to different ports on the same server, on ports 5500 and 5501.  The third copy is sent to 192.0.2.20, port 6343.

```
# sflowtool -4 -p 6343 -f 127.0.0.1/5500 -f 127.0.0.1/5501 -f 192.0.2.20/6343
```

This example could be used for handling P2P traffic graphs and BGP session detection on one machine, while sending a third sflow data feed to a separate server for IXP development or debugging.  The two local sflow feeds can be read using `sflowtool`:

```
# sflowtool -4 -p 5500 -l
# sflowtool -4 -p 5501 -l
```

The `sflowtool` fanout daemon should be started by the normal operating system daemon startup mechanism, e.g. script in a `rc.d` or `init.d` directory, or by a manual entry in `/etc/rc.local`.

If running `sflowtool` version 3.23 or greater, it is important to use the `-4` command-line parameter in sflowtool because otherwise it will listen on both ipv4 and ipv6 sockets. If you have an `sflowtool` process attempting to listen on a wildcard socket, it will stop other `sflowtool` processes from starting.
