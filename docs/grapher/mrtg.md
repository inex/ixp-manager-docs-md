# Backend: MRTG

MRTG is used to generate interface graphs. MRTG is a particularly efficient SNMP poller as, irrespective of how many times an interface is referenced for different graphs, it is only polled once per run. If you want to understand MRTG related options in this section, please refer to [MRTG's own documentation](https://oss.oetiker.ch/mrtg/doc/mrtg.en.html).

Per-second graphs are generated for bits, packets, errors, discards and broadcasts at 5min intervals. **IXP Manager**'s *Grapher* system can use MRTG to poll switches and create traffic graphs for:

* **Aggregate IXP and Infrastructure Graphs**

    The MRTG script creates aggregate graphs for the entire IXP as well as per-infrastructure graphs. These graphs are available from the *Statistics* menu under *Overall Peering Graphs*. Also, the graphs on the admin dashboard are versions of these.

    IXP and infrastructure graphs are aggregate graphs of edge / member ports only. It is the aggregate of traffic exchanged between the members of the IXP and thus does not include core / trunk ports between switches.

    You'll find examples of [IXP graphs](https://www.inex.ie/ixp/statistics/ixp) and [infrastructure graphs](https://www.inex.ie/ixp/statistics/infrastructure) on INEX's own [IXP Manager](https://www.inex.ie/ixp/) where they are public be default.

* **Per-Facility Aggregate Graphs**

    These are defined and built automatically from the locations / facilities you have defined and the switches you have assigned to them. These graphs are available from the *Statistics* menu under *Facility Aggregate Graphs*.

    These graphs are the aggregate of all peering ports **excluding** core/trunk ports in a given location / facility. It is the aggregate of traffic originating and/or terminating in a location rather than traffic simply passing through a location.

    You'll find examples of [facility graphs](https://www.inex.ie/ixp/statistics/location) on INEX's own [IXP Manager](https://www.inex.ie/ixp/) where they are public be default.


* **Switch Aggregate Graphs**

    These are defined and built automatically from the switches you have defined. These graphs are available from the *Statistics* menu under *Switch Aggregate Graphs*.

    These graphs are the aggregate of all peering ports **and core/trunk ports** on a given switch. It is the aggregate of traffic being exchanged across a given switch.

    You'll find examples of [switch graphs](https://www.inex.ie/ixp/statistics/switch) on INEX's own [IXP Manager](https://www.inex.ie/ixp/) where they are public be default.

* **Inter-Switch / Trunk Graphs**

    From IXP Manager v6, this is now handled via Core Bundles. Please see the [graphing section of the core bundles page](../features/core-bundles.md#graphing) for details.

    For older versions of IXP Manager, it can be done manually via the [config/grapher_trunks.php.dist](https://github.com/inex/IXP-Manager/blob/main/config/grapher_trunks.php.dist) file. **This is now deprecated and will be removed during the lifetime of the v6 release.**

    In either case, these graphs will be available in the *Statistics* menu. You can see [examples from INEX here](https://www.inex.ie/ixp/statistics/trunk).

* **Customer Graphs**

    MRTG creates: per port (physical interface); per LAG (virtual interface); and per customer aggregate graphs for each member / customer.

## MRTG Setup and Configuration

You need to install some basic packages for MRTG to work - on Ubuntu for example, install:

```sh
apt install rrdtool mrtg
```

You also need a folder to store all MRTG files. For example:

```sh
mkdir -p /srv/mrtg
```

In your `.env, you need to set the following options:

```
# The MRTG database type to use - either log or rrd:
GRAPHER_BACKEND_MRTG_DBTYPE="rrd"

# Where to store log/rrd/png files. This is from the perspective
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

## Generating MRTG Configuration

You can now generate a MRTG configuration by executing a command such as:

```sh
# Move to the directory where you have installed IXP Manager (typically: /srv/ixpmanager)
cd $IXPROOT

# Generate MRTG configuration and output to stdout:
php artisan grapher:generate-configuration -B mrtg

# Generate MRTG configuration and output to a named file:
php artisan grapher:generate-configuration -B mrtg -O /tmp/mrtg.cfg.candidate
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
cat $TMPCONF         | egrep -v '^#.*$' | \
    egrep -v '^[ ]+Based on configuration last generated by.*$' >${TMPCONF}.filtered
diff /tmp/mrtg.cfg.filtered ${TMPCONF}.filtered >/dev/null
DIFF=$?

rm /tmp/mrtg.cfg.filtered
rm ${TMPCONF}.filtered

if [[ $DIFF -eq 0 ]]; then
    rm ${TMPCONF}
    exit 0
fi

/usr/bin/mrtg --check ${TMPCONF}                 \
    && /bin/mv ${TMPCONF} /etc/mrtg.cfg          \
    && /etc/rc.d/mrtg_daemon restart > /dev/null
```

If your MRTG collector is on a different server, you could use a script such as the following to safely update MRTG via [IXP Manager's API](../features/api.md).

```sh
#! /usr/bin/env bash

# Temporary configuration file:
TMPCONF=/etc/mrtg.cfg.$$

# Download the configuration via the API. Be sure to replace 'your_api_key'
# with your actual API key (see API documentation).
curl --fail -s -H "X-IXP-Manager-API-Key: your_api_key" \
    https://ixp.example.com/api/v4/grapher/mrtg-config >${TMPCONF}

if [[ $? -ne 0 ]]; then
    echo "WARNING: COULD NOT FETCH UP TO DATE MRTG CONFIGURATION!"
    exit -1
fi

cd /etc

# Remove comments and date/time stamps for before comparing for differences
cat mrtg.cfg    | egrep -v '^#.*$' | \
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

/usr/bin/mrtg --check ${TMPCONF} && /bin/mv ${TMPCONF} /etc/mrtg.cfg



/usr/bin/mrtg --check ${TMPCONF}                 \
    && /bin/mv ${TMPCONF} /etc/mrtg.cfg          \
    && /etc/rc.d/mrtg_daemon restart > /dev/null
```

Note that the MRTG configuration that IXP Manager generates instructs MRTG to run as a daemon. On FreeBSD, MRTG comes with an initd script by default and you can kick it off on boot with something like the following in `/etc/rc.conf`:

```
mrtg_daemon_enable="YES"
mrtg_daemon_config="/etc/mrtg.cfg"
```

On Ubuntu it does not but it comes with a `/etc/cron.d/mrtg` file which kicks it off every five minutes (it will daemonize the first time and further cron jobs will have no effect).

Marco d'Itri provided Ubuntu / Debian compatible systemd configurations for mrtg which you can find detailed in [this Github issue](https://github.com/inex/IXP-Manager/issues/627).

To start and stop it via the older initd scripts on Ubuntu, use an initd script such as this: [ubuntu-mrtg-initd](https://github.com/inex/IXP-Manager/blob/main/tools/runtime/mrtg/ubuntu-mrtg-initd)  ([source](http://www.iceflatline.com/2009/08/how-to-install-and-configure-mrtg-on-ubuntu-server/)):

```
cp ${IXPROOT}/tools/runtime/mrtg/ubuntu-mrtg-initd /etc/init.d/mrtg
chmod +x /etc/init.d/mrtg
update-rc.d mrtg defaults
/etc/init.d/mrtg start
```

And disable the default cron job for MRTG on Ubuntu (`/etc/cron.d/mrtg`).


## Customising the Configuration

Generally speaking, you should not customize the way IXP Manager generates MRTG configuration as the naming conventions are tightly coupled to how IXP Manager fetches the graphs. However, if there are bits of the MRTG configuration you need to alter, you can do it via [skinning](../features/skinning.md). *The skinning documentation actually uses MRTG as an example.*


## Inserting Traffic Data Into the Database / Reporting Emails

The MRTG backend inserts daily summaries into MySQL for reporting. See the `traffic_daily` and `traffic_daily_phys_ints` database tables for this. Essentially, there is a row per day per customer in the first and a row per physical interface in the second for traffic types *bits, discards, errors, broadcasts and packets*. Each row has a daily, weekly, monthly and yearly value for average, max and total.

The [task scheduler](../features/cronjobs.md) handles collecting and storing *yesterday's* data. If you are using an older version, create a cron job such as:

```
0 2   * * *   www-data        /srv/ixpmanager/artisan grapher:upload-stats-to-db
5 2   * * *   www-data        /srv/ixpmanager/artisan grapher:upload-pi-stats-to-db
```

In the IXP Manager application, the `traffic_daily` data powers the *League Table* function and the `traffic_daily_phys_int` data powers the *Utilisation* function - both on the left hand menu.

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
2. Email a report of all ports with >=80% utilisation yesterday (this uses the MRTG files as it predates the `traffic_daily_phys_ints` table).
3. Email a report of all ports with a non-zero discard count yesterday.
4. Email a report of all ports with a non-zero error count yesterday.


This generated emails are HTML formatted with embedded graph images.


## Port Utilisation

There exists a port utilisation reporting function into IXP Manager's frontend UI. You will find it in the *IXP STATISTICS*  section of the left hand side menu.

The purpose of this tool is to easily identify ports that are nearing or exceeding 80% utilisation. In its default configuration, IXP Manager will iterate over all the physical interface (switch ports) MRTG log files for every member and insert that information into the database at 02:10 (AM).

In the UI, when you select a specific date and period (day/week/month/year), you are shown the maximum port utilisation (in and out) for the given period up to 02:10 on that day.

This feature was introduced in March 2020 during the Coronavirus outbreak. After observing as much as 50% routine traffic increases across IXPs in areas under lock down, we needed a tool that would allow us to rapidly and easily view port utilisations across all members rather than looking at member graphs individually.




## Troubleshooting

### General Notes

* If you have difficulty getting MRTG to work, please also refer the MRTG documentation at https://oss.oetiker.ch/mrtg/doc/mrtg.en.html
* Any references to installing MRTG above are guidelines from our own experience. IXP Manager's role is to generate a configuration file for MRTG. It is up to the user to install MRTG as they deem appropriate.
* The above assumes that MRTG automatically reconfigures itself when the configuration changes [as stated in the MRTG documentation for *RunAsDaemon*](https://oss.oetiker.ch/mrtg/doc/mrtg-reference.en.html). We have seen inconsistent behaviors for this and if it does not work for you, you will need to add a step to restart the MRTG daemon to the reconfiguration script above (at the very end).
* The Ubuntu example above was a pre-systemd example. If anyone has an example of a systemd MRTG daemon configuration please provide us with some updated documentation.

### Missing Graphs

A common issue raised on the mailing list is missing customer graphs. The code which generates MRTG configuration is [in the MRTG backend file](https://github.com/inex/IXP-Manager/blob/main/app/Services/Grapher/Backend/Mrtg.php) (see the function `getPeeringPorts()`).

The conditions for a physical interface allocated to a customer to make the configuration file are:

* the physical interface state must be either *Connected* or *Quarantine*.
* the switch must be *active* and *pollable*.

If you are not sure about how ports are configured in IXP Manager, please see [the interfaces document](../usage/interfaces.md).

You can check the physical interface state by:

1. goto the customer's overview page (select customer from dropdown menu on top right).
2. select the *Ports* tab.
3. edit the port via the *Pencil* icon next to the connection you are interested in.
4. find the physical interface under *Physical Interfaces* and edit it via the *Pencil* icon on the right hand side of the row.
5. **Status** should be either *Connected* or *Quarantine*.

You can ensure a switch is active by:

1. Select *Switches* from the left hand side *IXP ADMIN ACTIONS* menu.
2. Click *Include Inactive* on the top right heading.
3. Find the switch where the physical interface is and ensure *Active* is checked.
