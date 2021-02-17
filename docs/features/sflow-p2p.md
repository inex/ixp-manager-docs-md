# Configuring peer-to-peer statistics

The IXP Manager sflow peer-to-peer graphing system depends on the [MAC address database](layer2-addresses.md) system so that point to point traffic flows can be identified.  Before proceeding further, this should be configured so that when you click on either the `MAC Addresses | Discovered Addresses` or `MAC Addresses | Configured Addresses` links from the admin portal, you should see a MAC address associated with each port.  If you cannot see any MAC address in either database, then the sflow peer-to-peer graphing mechanism will not work. This needs to be working properly before any attempt is made to configure sflow peer-to-peer graphing. The sflow p2p graphing system can use either discovered MAC addresses or configured MAC addresses, but not both.

# Server Overview

As sflow can put a reasonably high load on a server due to disk I/O for RRD file updates - it is recommended practice to use a separate server (or virtual server) to handle the IXP's sflow system. The sflow server will need:

* Apache (or any other web server)
* sflowtool
* git
* rrdtool + rrdcached
* perl 5.10.2 or later
* mrtg (for Net_SNMP_util)
* a filesystem partition mounted with the `noatime`, `nodiratime` options, and which has enough disk space.  You may also want to consider disabling filesystem journaling.

# Configuration

### FreeBSD
```
pkg install apache24 sflowtool git databases/rrdtool mrtg
```

### Ubuntu
```
apt-get install apache2 git rrdtool rrdcached mrtg
```

`sflowtool` is not part of the Ubuntu / Debian package archive and must be compiled from source if running on these systems.  The source code can be found on Github:  https://github.com/sflow/sflowtool.

Once the required packages are installed, the IXP Manager peer-to-peer graphing system can be configured as follows:

* Clone the IXP Manager installation using `git clone https://github.com/inex/IXP-Manager /srv/ixpmanager`.
* Check what perl libraries need to be installed using the `tools/runtime/check-perl-dependencies.pl` command.  These libraries will need to be manually installed.
* Install the IXP Manager perl library in the `tools/perl-lib/IXPManager` directory (`perl Makefile.PL; make install`)
* configure and start `rrdcached`.  We recommend using journaled mode with the `-P FLUSH,UPDATE -m 0666 -l unix:/var/run/rrdcached.sock` options enabled.  Note that these options allow uncontrolled write access to the RRD files from anyone on the sflow machine, so precautions should be taken to limit access to this server to ensure that this cannot be abused.

On FreeBSD it is advisable to set `net.inet.udp.blackhole=1` in `/etc/sysctl.conf`, to stop the kernel from replying to unknown sflow packets with an ICMP unreachable reply.

## ixpmanager.conf

The following sflow parameters must be set in the `<ixp>` section:

* `sflow_rrdcached`: set to 0 or 1, depending on whether you want to use rrdcached or not.
* `sflowtool`: the location of the sflowtool binary.
* `sflowtool_opts`: command-line options to pass to sflowtool
* `sflow_rrddir`: the directory where all the sflow .rrd files will be stored.
* `apikey`: a valid API key.  Instructions for configuring this can be found in the [API configuration](api.md) documentation.
* `apibaseurl`: the base URL of the IXP Manager API.  E.g. if you log into IXP Manager using `https://ixp.example.com/`, then `apibaseurl` will be `https://ixp.example.com/api/v4`.
* `macdbtype`: `configured|discovered` - specifies whether the sflow p2p graphing system should pull MAC address information from the Configured MAC address database or the Discovered MAC address database.  By default, it uses the Discovered MAC address database.  If you wish to use the Configured MAC address database, then this should be set to `configured`.

Note that the `<sql>` section of `ixpmanager.conf` will need to be configured either if you are running `update-l2database.pl` or the sflow BGP peering matrix system.  The `sflow-to-rrd-handler` script uses API calls and does not need SQL access.

An example ixpmanager.conf might look like this:

```
<sql>
        dbase_type      = mysql
        dbase_database  = ixpmanager
        dbase_username  = ixpmanager_user
        dbase_password  = blahblah
        dbase_hostname  = sql.example.com
</sql>

<ixp>
        sflowtool = /usr/bin/sflowtool
        sflowtool_opts = -4 -p 6343 -l
        sflow_rrdcached = 1
        sflow_rrddir = /data/ixpmatrix

        apikey = APIKeyFromIXPManager
        apibaseurl = http://www.example.com/ixp/api/v4
        macdbtype = configured
</ixp>
```

This file should be placed in `/usr/local/etc/ixpmanager.conf`

# Starting sflow-to-rrd-handler

The `tools/runtime/sflow/sflow-to-rrd-handler` command processes the output from sflowtool and injects it into the RRD archive.  This command should be configured to start on system bootup.

If you are running on FreeBSD, this command can be started on system bootup by copying the `tools/runtime/sflow/sflow_rrd_handler` script into `/usr/local/etc/rc.d` and modifying the `/etc/rc.conf` command to include:

```
sflow_bgp_handler_enable="YES"
```

# Displaying the Graphs

The IXP Manager web GUI requires access to the sflow p2p .rrd files over http or https.  This means that the sflow server must run a web server (e.g. Apache), and the IXP Manager GUI must be configured with the URL of the RRD archive on the sflow server.

Assuming that `ixpmanager.conf` is configured to use `/data/ixpmatrix` for the RRD directory, these files can be server over HTTP using the following Apache configuration:

```
Alias /grapher-sflow /data/ixpmatrix
<Directory "/data/ixpmatrix">
        Options None
        AllowOverride None
</Directory>
```

The IXP Manager `.env` file must be configured with parameters both to enable sflow and to provide the front-end with the HTTP URL of the back-end server.  Assuming that the sflow p2p server has IP address 10.0.0.1, then the following lines should be added to `.env`:

```
GRAPHER_BACKENDS="mrtg|sflow|smokeping"
GRAPHER_BACKEND_SFLOW_ENABLED=true
GRAPHER_BACKEND_SFLOW_ROOT="http://10.0.0.1/grapher-sflow"
```

<!--
# Sflowtool fanout

If IXP Manager is configured with more than one component which requires an sflow feed (e.g. [Peering Matrix](Peering-Matrix) support), then it will be necessary to configure `sflowtool` to use [sflow fan-out](sflow-fanout.md).
-->

# RRD Requirements

Each IXP edge port will have 4 separate RRD files for recording traffic to each other participant on the same VLAN on the IXP fabric: ipv4 bytes, ipv6 bytes, ipv4 packets and ipv6 packets.  This means that the number of RRD files grows very quickly as the number of IXP participants increases.  Roughly speaking, for every N participants at the IXP, there will be about 4*N^2 RRD files.  As this number can create extremely high I/O requirements on even medium sized exchanges, IXP Manager requires that `rrdcached` is used.

# Troubleshooting

There are plenty of things which could go wrong in a way which would stop the sflow mechanism from working properly.

* the Mac Address table in IXP manager is populated correctly with all customer MAC addresses using the `update-l2database.pl` script, if you are using discovered MAC addresses. If you're using configured MAC addresses, you can ignore `update-l2database.pl` script completed but you should make sure that there are valid MAC addresses associated with each port you're attempting to monitor.
* ensuring that all switch ports are set up correctly in IXP Manager, i.e. Core ports and Peering ports are configured as such
* ensuring that sflow accounting is configured on peering ports and is disabled on all core ports
* ensuring that sflow accounting is as ingress-only
* Using Arista / Cisco / Dell F10 kit with LAGs?  Make sure you configure the port channel name in the Advanced Options section of the customer's virtual interface port configuration.
* if the `sflow-to-rrd-handler` script crashes, this may indicate that the back-end filesystem is overloaded.  Installing rrdcached is a first step here.  If it crashes with rrdcached enabled, then you need more disk I/O (SSDs, etc).
* it is normal to see about 5% difference between sflow stats and mrtg stats.  These differences are hardware and software implementation dependent.  Every switch manufacturer does things slightly differently.
* if there is too much of a difference between the sflow p2p individual aggregate stats and the port stats from the main graphing system, it might be that the switch is throttling sflow samples.  It will be necessary to check the maximum sflow pps rate on the switch processor, compare that with the pps rate in the Switch Statistics graphs and work out the switch process pps throughput on the basis of the sflow sample rate.   Increasing the sflow sampling ration may help, at the cost of less accurate graphs for peering sessions with low traffic levels.

# FreeBSD, really?

No.  All of this runs perfectly well on Ubuntu (or your favourite Linux distribution).

INEX runs its sflow back-end on FreeBSD because we found that the UFS filesystem performs better than the Linux ext3 filesystem when handling large RRD archives.  If you run `rrdcached`, it's unlikely that you will run into performance problems.  If you do, you can engineer around them by running the RRD archive on a PCIe SSD.

# API Endpoints

The `tools/runtime/sflow/sflow-to-rrd-handler` script from **IXP Manager** referenced above uses an IXP Manager API endpoint to associate sflow samples (based on source and destination MAC addreesses) with VLAN interfaces.

As IXP Manager [supports layer2 / MAC addresses](layer2-addresses.md) in two ways (learned versus configured), there are two endpoints (using `https://ixp.example.com` as your IXP Manager installation):

1. Learned: `https://ixp.example.com/api/v4/sflow-db-mapper/learned-macs`
2. Configured: `https://ixp.example.com/api/v4/sflow-db-mapper/configured-macs`

The JSON output is structured as per the following example:

```
{
    "infrastructure id": {
        "vlan tag": {
            "mac address": "vlan interface id",
            ...
        },
        ...
    },
    ...
}
```

where:

* the outer objects are indexed by an infrastructure ID
* each infrastructure object has VLAN objects indexed by the VLAN **tag** *(this is not the VLAN database ID but the VLAN tag)*
* each VLAN object has key/value pairs of `"macaddress": "vlaninterfaceid"`
