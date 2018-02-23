# Grapher

The biggest new feature available at launch in IXP Manager v4 is a new graphing system called *Grapher*.

*Grapher* is a complete rewrite of all previous graphing code and includes:

- API access to graphs and graph statistics
- multiple backends (such as MRTG, sflow) with dynamic resolution of appropriate backend
- configuration generation where required
- consistent and flexible OOP design

To date, we have developed the following reference backend implementations:

1. ``dummy`` - a dummy grapher that just provides a placeholder graph for all possible graph types;
2. ``mrtg`` - MRTG graphing using either the log or rrd backend. Use cases for MRTG are L2 interface statistics for bits / packets / errors / discards / broadcasts per second. Aggregate graphs for customer LAGs, overall customer traffic, all traffic over a switch / infrastructure / the entire IXP are all supported.
3. ``sflow`` - while the MRTG backend looks at layer 2 statistics, sflow is used to provide layer 3 statistics such as per protocol (IPv4/6) graphs and peer to peer graphs.
4.``smokeping`` - (available from v4.8.0) this replaces the previous way we used to access Smokeping graphs. See [the Smokeping documenation](smokeping.md) for more information.

In a typical production environment, you'd implement MRTG, Smokeping and sflow to provide the complete set of features.

## Configuration

There is only a handful of configuration options required and a typical and complete `$IXPROOT/.env` would look like this:

```
GRAPHER_BACKENDS="mrtg|sflow|smokeping"
GRAPHER_CACHE_ENABLED=true

GRAPHER_BACKEND_MRTG_DBTYPE="rrd"
GRAPHER_BACKEND_MRTG_WORKDIR="/srv/mrtg"
GRAPHER_BACKEND_MRTG_LOGDIR="/srv/mrtg"

GRAPHER_BACKEND_SFLOW_ENABLED=true
GRAPHER_BACKEND_SFLOW_ROOT="http://sflow-server.example.com/grapher-sflow"

GRAPHER_BACKEND_SMOKEPING_ENABLED=true
GRAPHER_SMOKEPING_URL="http://smokeping-server.example.com/smokeping"
```

For those interested, the complete Grapher configuration file can be seen in [`$IXPROOT/config/grapher.php](https://github.com/inex/IXP-Manager/blob/master/config/grapher.php). Remember: put your own local changes in `.env` rather than editing this file directly.


The global (non-backend specific) options are:

* `GRAPHER_BACKENDS` - in a typical production environment this would be `"mrtg|sflow|smokeping"` which means *try the MRTG backend first, then sflow and then smokeping*. We ship with this set as `"dummy"` so you can see sample graphs working out of the box.
* `GRAPHER_CACHE_ENABLED` - the IXP industry standard for graphing is to graph at 5min intervals. With the cache enabled, IXP Manager does not have to regenerate / reload / reprocess log / rrd / image files if we have cached them and they are less than 5mins old. This is enabled by default which is the recommended setting.

Backend specific configuration and set-up instructions can be found in their own sections below.


## Grapher Backends

## Backend: MRTG

MRTG is a particularly efficient SNMP poller as, irrespective of how many times an interface is referenced for different graphs, it is only polled once per run. If you want to understand MRTG related options in this section, please refer to MRTG's own documenation: https://oss.oetiker.ch/mrtg/doc/mrtg.en.html

Per-second graphs are generated for bits, packets, errors, discards and broadcasts at 5min intervals. IXP Manager's Grapher system can use MRTG to poll switches and create traffic graphs for:

* **Aggregate IXP and Infrastructure Graphs**

  The MRTG script creates aggregate graphs for the entire IXP as well as per-infrastructure graphs. These graphs are available from the *Statistics* menu under *Overall Peering Graphs*. Also, the graphs on the admin dashboard are the monthly versions of these and will appear on the dashboard when configured as above.

* **Switch Aggregate Graphs**

  These are defined and built automatically from the switches you have defined. These graphs are the aggregate of all peering ports. These graphs are available from the *Statistics* menu under *Switch Aggregate Graphs*.

* **Inter-Switch / Trunk Graphs**

  IXP Manager does not currently support a frontend means of creating these definitions (but, as of late 2017, it is being worked on). For now, we do it manually via the [IXP Manager v3 way](https://github.com/inex/IXP-Manager/wiki/MRTG---Traffic-Graphs#inter-switch--trunk-graphs).

  These graphs will be available in the *Statistics* menu under *Inter-Switch / PoP Graphs*.

* **Customer Graphs**

  MRTG creates per port, per LAG and aggregate graphs for each member / customer.

### MRTG Setup and Configuration

You need to install some basic packages for MRTG to work - on Ubuntu for example, install:

```sh
apt-get install rrdtool mrtg
```

You also need a folder to store all MRTG files. For example:

```sh
mkdir -p /srv/mrtg
```

In your `.env, you need to set the following options:

```
# The MRTG database type to use - either log or rrd:
GRAPHER_BACKEND_MRTG_DBTYPE="rrd"

# Where to store log/rrd/png files as created above. This is from the perspective
# of the mrtg daemon and it is only used when generating the mrtg configuration
# file so this should be a local path on whatever server mrtg will run:
GRAPHER_BACKEND_MRTG_WORKDIR="/srv/mrtg"

# Where IXP Manager can fine the GRAPHER_BACKEND_MRTG_WORKDIR above. If mrtg is
# running on the same server as IXP Manager, this this would just be the same:
GRAPHER_BACKEND_MRTG_LOGDIR="/srv/mrtg"
# Note that if you wish to run MRTG on another server, you can expose the
# WORKDIR on a HTTP server and provide a URL to this option:
# GRAPHER_BACKEND_MRTG_LOGDIR="http://collector.example.com/mrtg"
```

You can now generate a MRTG configuration by executing a command such as:

```sh
# Move to the directory where you have installed IXP Manager (typically: /srv/ixpmanager)
cd $IXPROOT

# Generate MRTG configuration and output to stdout:
./artisan grapher:generate-configuration -B mrtg

# Generate MRTG configuration and output to a named file:
./artisan grapher:generate-configuration -B mrtg -O /tmp/mrtg.cfg.candidate
```

You could also combine a syntax check before putting the resultant file live. Here's a complete example that could be run via cron:

```sh
#! /usr/bin/env bash

# Set this to the directory where you have installed IXP Manager (typically: /srv/ixpmanager)
IXPROOT=/srv/ixpmanager

# Temporary configuration file:
TMPCONF=/tmp/mrtg.cfg.$$

# Synchronize configuration files
${IXPROOT}/artisan grapher:generate-configuration -B mrtg -O $TMPCONF

# Remove comments and date/time stamps for before comparing for differences
cat /etc/mrtg.cfg    | egrep -v '^#.*$' | \
    egrep -v '^[ ]+Based on configuration last generated by.*$' >/tmp/mrtg.cfg.filtered
cat $TMPCONF         | egrep -v '^#.*$' |
    egrep -v '^[ ]+Based on configuration last generated by.*$' >${TMPCONF}.filtered
diff /tmp/mrtg.cfg.filtered ${TMPCONF}.filtered >/dev/null
DIFF=$?

rm /tmp/mrtg.cfg.filtered
rm ${TMPCONF}.filtered

if [[ $DIFF -eq 0 ]]; then
    rm ${TMPCONF}
    exit 0
fi

/usr/bin/mrtg --check ${TMPCONF} && /bin/mv ${TMPCONF} /etc/mrtg.cfg
```

If your MRTG collector is on a different server, you could use a script such as the following to safely update MRTG via [IXP Manager's API](api.md).

```sh
#! /usr/bin/env bash

# Temporary configuration file:
TMPCONF=/etc/mrtg/mrtg.cfg.$$

# Download the configuration via the API. Be sure to replace 'your_api_key'
# with your actual API key (see API documenation).
curl --fail -s -H "X-IXP-Manager-API-Key: your_api_key" \
    https://ixp.example.com/api/v4/grapher/mrtg-config >${TMPCONF}

if [[ $? -ne 0 ]]; then
    echo "WARNING: COULD NOT FETCH UP TO DATE MRTG CONFIGURATION!"
    exit -1
fi

cd /etc/mrtg

# Remove comments and date/time stamps for before comparing for differences
cat mrtg.cfg    | egrep -v '^#.*$' |
    egrep -v '^[ ]+Based on configuration last generated by.*$' >mrtg.cfg.filtered
cat ${TMPCONF}  | egrep -v '^#.*$' | \
    egrep -v '^[ ]+Based on configuration last generated by.*$' >${TMPCONF}.filtered
diff mrtg.cfg.filtered ${TMPCONF}.filtered >/dev/null
DIFF=$?

rm mrtg.cfg.filtered
rm ${TMPCONF}.filtered

if [[ $DIFF -eq 0 ]]; then
    rm ${TMPCONF}
    exit 0
fi

/usr/bin/mrtg --check ${TMPCONF} && /bin/mv ${TMPCONF} /etc/mrtg/mrtg.cfg     
```

Note that the MRTG configuration that IXP Manager generates instructs MRTG to run as a daemon. On FreeBSD, MRTG comes with an initd script by default and you can kick it off on boot with something like the following in `/etc/rc.conf`:

```
mrtg_daemon_enable="YES"
mrtg_daemon_config="/etc/mrtg/mrtg.cfg"
```

However, on Ubuntu it does not but it comes with a `/etc/cron.d/mrtg` file which kicks it off every five minutes (it will daemonize the first time and further cron jobs will have no effect).

To start and stop it via standard initd scripts on Ubuntu, use an initd script such as this: [ubuntu-mrtg-initd](https://github.com/inex/IXP-Manager/blob/master/tools/runtime/mrtg/ubuntu-mrtg-initd)  ([source](http://www.iceflatline.com/2009/08/how-to-install-and-configure-mrtg-on-ubuntu-server/)):

```
cp ${IXPROOT}/tools/runtime/mrtg/ubuntu-mrtg-initd /etc/init.d/mrtg
chmod +x /etc/init.d/mrtg
update-rc.d mrtg defaults
/etc/init.d/mrtg start
```

And disable the default cron job for MRTG on Ubuntu (`/etc/cron.d/mrtg`).

**Important notes:**

* If you have difficulty getting MRTG to work, please also refer the MRTG documentation at https://oss.oetiker.ch/mrtg/doc/mrtg.en.html
* Any references to installing MRTG above are guidelines from our own experience. IXP Manager's role is to generate a configuration file for MRTG. It is up to the user to install MRTG as they deem appropriate.
* The above assumes that MRTG automatically reconfigures itself when the configuration changes [as stated in the MRTG documentation for *RunAdDaemon*](https://oss.oetiker.ch/mrtg/doc/mrtg-reference.en.html). We have seen inconsistent behaviors for this and if it does not work for you, you will need to add a step to restart the MRTG daemon to the reconfiguration script above (at the very end).
* The Ubuntu example above was a pre-systemd example. If anyone has an example of a systemd MRTG daemon configuration please provide us with some updated documentation.

### Customising the Configuration

Generally speaking, you should not customize the way IXP Manager generates MRTG configuration as the naming conventions are tightly coupled to how IXP Manager fetches the graphs. However, if there are bits of the MRTG configuration you need to alter, you can do it via [skinning](skinning.md). *The skinning documenation actually uses MRTG as an example.*


### Inserting Traffic Data Into the Database / Reporting Emails

The MRTG backend inserts daily summaries into MySQL for reporting. See the `traffic_daily` database table for this. Essentially, there is a row per day per customer for traffic types *bits, discards, errors, broadcasts and packets*. Each row has a daily, weekly, monthly and yearly value for average, max and total.

 An example crontab for collecting and storing *yesterday's* data is as follows. **This should run everyday.**

```
0 2   * * *   www-data        /srv/ixpmanager/artisan grapher:upload-stats-to-db
```

In the IXP Manager application, this data powers the *League Table* function on the left hand menu.

This data is also used to send email reports / notifications of various traffic events. A sample crontab for this would look like the following:

```
0 4   * * *   www-data        /srv/ixpmanager/artisan grapher:email-traffic-deltas    \
                                --stddev=1.5 -v user1@example.com,user2@example.com

30 10 * * tue www-data        /srv/ixpmanager/artisan grapher:email-port-utilisations \
                                --threshold=80 user1@example.com,user2@example.com

31 10 * * *   www-data        /srv/ixpmanager/artisan grapher:email-ports-with-counts \
                                --discards user1@example.com,user2@example.com

32 10 * * *   www-data        /srv/ixpmanager/artisan grapher:email-ports-with-counts \
                                --errors user1@example.com,user2@example.com
```

Which, in the order above, do:

1. Email a report of members whose average traffic has changed by more than 1.5 times their standard deviation.
3. Email a report of all ports with >=80% utilisation yesterday.
4. Email a report of all ports with a non-zero discard count yesterday.
5. Email a report of all ports with a non-zero error count yesterday.


This generated emails are HTML formatted with embedded graph images.


## Backend: sflow

Documentation on sflow is being prepared for v4 but the [v3 documentation is still available here](https://github.com/inex/IXP-Manager/wiki/Installing-Sflow-Support).

The previous version of IXP Manager (<4) used a script called `sflow-graph.php` which was installed on the sflow server to create graphs on demand. IXP Manager v4 does not use this but pulls the required RRD files directly.

If you have these on the same server (not typically recommended), then set the path accordingly in `.env`:

```
GRAPHER_BACKEND_SFLOW_ROOT="/srv/ixpmatrix"
```

If you have implemented this via a web server on a dedicated sflow server (as we typically do at INEX), then you need to expose the RRD data directory to IXP Manager using an Apache config such as:

```
Alias /grapher-sflow /srv/ixpmatrix

<Directory "/srv/ixpmatrix">
    Options None
    AllowOverride None
    <RequireAny>
            Require ip 192.0.2.0/24
            Require ip 2001:db8::/32
    </RequireAny>
</Directory>
```

and update `.env` for this with something like:

```
GRAPHER_BACKEND_SFLOW_ROOT="http://www.example.com/grapher-sflow"
```


## Accessibility of Aggregate Graphs

By default, the following graphs are **publically** accessible in **IXP Manager** and available through the top menu under *Statistics*:

1. aggregate bits and packets graphs for the IXP;
2. aggregate bits and packets graphs for the infrastructures;
3. aggregate graphs for the switches; and
4. aggregate graphs for the trunk connections.

If you wish to limit access to these to a *less than or equal* [user permission](../usage/users.md), see the `config/grapher.php` configuration file and set the following in `.env` appropriately:

1. `GRAPHER_ACCESS_IXP`
2. `GRAPHER_ACCESS_INFRASTRUCTURE`
3. `GRAPHER_ACCESS_SWITCH`
4. `GRAPHER_ACCESS_TRUNK`

*The older Zend Framework templates will still show these options in the menu but these templates are beign agressivily phased out.*

## API Access

*Grapher* allows API access to graphs via a base URL of the form:

```
https://ixp.example.com/grapher/{graph}[?id=x][&period=x][&type=x][&category=x] \
    [&protocol=x][&backend=x]
```

Here's two quick examples from INEX's production system:

1. Aggregate exchange traffic options: [https://www.inex.ie/ixp/grapher/ixp?id=1&type=json](https://www.inex.ie/ixp/grapher/ixp?id=1&type=json)
2. Aggregate exchange traffic PNG: [https://www.inex.ie/ixp/grapher/ixp](https://www.inex.ie/ixp/grapher/ixp) (as you'll learn below, the defaults are `id=1&type=png`).

A sample of the JSON output is:

```json
{
    class: "ixp",
    urls: {
        png: "https://www.inex.ie/ixp/grapher/ixp?period=day&type=png&category=bits&protocol=all&id=1",
        log: "https://www.inex.ie/ixp/grapher/ixp?period=day&type=log&category=bits&protocol=all&id=1",
        json: "https://www.inex.ie/ixp/grapher/ixp?period=day&type=json&category=bits&protocol=all&id=1"
    },
    base_url: "https://www.inex.ie/ixp/grapher/ixp",
    statistics: {
        totalin: 13733441895899552,
        totalout: 13734817210037696,
        curin: 183970331392,
        curout: 184222146544,
        averagein: 114930932321.55484,
        averageout: 114942441900.67783,
        maxin: 204976886344,
        maxout: 204800400448
    },
    params: {
        type: "json",
        category: "bits",
        period: "day",
        protocol: "all",
        id: 1
    },
    supports: {
        protocols: {
            all: "all"
        },
        categories: {
            bits: "bits",
            pkts: "pkts"
        },
        periods: {
            day: "day",
            week: "week",
            month: "month",
            year: "year"
        },
        types: {
            png: "png",
            log: "log",
            json: "json"
        }
    },
    backends: {
        mrtg: "mrtg"
    },
    backend: "mrtg"
}
```

You can see from the above what `params` were used to create the `statistics` (and would be used for the image if `type=png`), what parameters are supported (`supports`), what backends are available for the given graph type and mix of parameters, etc.

**Notes:**

1. not all backends support all options or graphs; use the `json` type to see what's supported *but remember that IXP Manager will, when configured correctly, chose the appropriate backend*;
2. the primary key IDs mentioned below are mostly available in the UI when viewing lists of the relavent objects;
3. an understanding of how IXP Manager represents interfaces is required to grasp the below - [see here](../usage/interfaces.md).

Let's first look at supported graphs:

* `ixp`: aggregate graph for an IXP's overall traffic. `id`, which defaults to `1`, is the primary key of the IXP from the `ixp` database table. As **IXP Manager** does not support multiple IXPs, this defaults to `id=1`. [Currently only supported via MRTG for `protocol=all`]


* `infrastructure`: aggregate graph for the overall traffic on a specific IXP infrastructure. For many IXPs, they'll just have a single infrastructure and this will go unused as it would be the equivalent of `ixp` above. `id`, which is mandatory, is the primary key of the infrastructure from the `infrastructure` database table. [Currently only supported via MRTG for `protocol=all`]


* `vlan`: aggregate graph for a specific VLAN. `id`, which is mandatory, is the primary key of the VLAN from the `vlan` database table. [Currently only supported via sflow for `protocol=ipv4|ipv6`]


* `switch`: aggregate graph of all peering traffic being switched by a specific switch (sum of all customer ports plus core ports). `id`, which is mandatory, is the primary key of the switch from the `switch` database table. [Currently only supported via MRTG for `protocol=all`]


* `trunk`: a legacy hold over from *Inter-Switch / Trunk Graphs* above to be replaced with core bundles.


* `phsyicalinterface`: traffic for an individual member port - a single physical switch port. `id`, which is mandatory, is the primary key of the physical interface from the `physicalinterface` database table. [Currently only supported via MRTG for `protocol=all`]


* `virtualinterface`: if a member has a single connection (one switch port) then this is the same as `phsyicalinterface` above. However, if they have a LAG port then it's the aggregate traffic for all physical ports in the LAG. `id`, which is mandatory, is the primary key of the virtual interface from the `virtualinterface` database table. [Currently only supported via MRTG for `protocol=all`]


* `customer`: the aggregate traffic for all ports belonging to a customer across all infrastructures. `id`, which is mandatory, is the primary key of the customer from the `cust` database table. [Currently only supported via MRTG for `protocol=all`]


* `vlaninterface`: aggregate traffic flowing through a members VLAN interface for a specific protocol. `id`, which is mandatory, is the primary key of the VLAN interface from the `vlaninterface` database table. [Currently only supported via sflow for `protocol=ipv4|ipv6`]


* `p2p`: peer to peer traffic between two member VLAN interfaces. The source (`svli`) and destination (`dvli`) VLAN interface IDs are required. `svli` and `dvli`, which are mandatory, are primary keys of the VLAN interfaces from the `vlaninterface` database table. [Currently only supported via sflow for `protocol=ipv4|ipv6`]


For additional options, it's always best to manually or programmatically examine the output for `type=json` to see what is supported. The following is a general list.

* `type`: one of:

    * `json` - as demonstrated and described above;
    * `log` - MRTG  log file type output formatted as a JSON array;
    * `rrd` - the RRD file for the requested graph type;
    * `png` - the graph image itself (default).
    * potentially others as supported / implemented by newer backends.



* `period`: one of `day`, `week`, `month`, `year`.


* `category`: one of `bits`, `pkts` (packets), `errs` (errors), `discs` (discards), `bcasts` (broadcasts). Bits is measured in bits per second, the rest in packets per second.


* `protocol`: one of `all`, `ipv4` or `ipv6`.


* `backend`: default is to let IXP Manager decide.


### API Access Control

The grapher API can be accessed using the [standard API access mechanisms](api.md).

Each graph (ixp, infrastructure, etc.) has an `authorise()` method which determines who is allowed view a graph. For example, see [IXP\Services\Grapher\Graph\VlanInterface::authorise()](https://github.com/inex/IXP-Manager/blob/master/app/Services/Grapher/Graph/VlanInterface.php#L131). The general logic is:

* if not logged in / valid API key -> deny
* if superuser -> allow
* if user belongs to customer graph requested -> allow
* otherwise -> deny and log

For the supported graph types, default access control is:

Graph               |  Default Access Control
--------------------|----------------------------------
`ixp`               | public but respects `GRAPHER_ACCESS_IXP` (see above)
`infrastructure`    | public but respects `GRAPHER_ACCESS_INFRASTRUCTURE` (see above)
`vlan`              | public unless it's a private VLAN (in which case only superuser is supported currently)
`switch`            | public but respects `GRAPHER_ACCESS_SWITCH` (see above)
`trunk`             | public but respects `GRAPHER_ACCESS_TRUNK` (see above)
`physicalinterface` | superuser or user of the owning customer
`vlaninterface`     | superuser or user of the owning customer
`virtualinterface`  | superuser or user of the owning customer
`customer`          | superuser or user of the owning customer
`p2p`               | superuser or user of the source (`svli`) owning customer
