# Layer2 / MAC Addresses

IXP Manager has support for layer2 / MAC addresses in two ways:

1. **MAC Addresses**: a read-only table via an admin menu option called *MAC Addresses* which lists entries from a database of MAC addresses which are sourced via a script from the IXP's switches directly. *(Available since version 3.x)*.
2. **Layer2 Addresses**: a managed table of layer2 addresses, viewed by the admin menu option *Layer2 Addresses*. These are assigned by IXP administrators on a per VLAN interface basis. *(Available since version 4.4)*.

## Layer2 Addresses

In early 2017, [INEX](https://www.inex.ie/) migrated its primary peering LAN from a flat layer2 with spanning tree design to a VxLAN set-up with automation via Salt and Napalm *(we will insert references to presentations here once we complete all required functionality)*.

Part of the requirements for this automation (and this was an existing feature request from other IXPs) was the management of layer2 addresses within IXP Manager and, rather than assigning them to a virtual interface, assign them to specific VLAN interfaces.

Outside of our automation and VxLAN, other uses included:

1. to potentially allow members to add a MAC address during maintenance and thus have the system update a layer2 acl on the switch(es);
2. a static maintained database of MAC addresses for EVPN;
3. a static maintained database for lookups.

The features of this system are listed below.

### Listing and Searching Existing Layer2 Addresses

There is a new menu option (left hand side menu) under *MAC/L2 Addresses* called *Layer2 Addresses*. This lists all configured layer2 addresses including the OUI manufacturer (see below), associated switch / switch port(s), customer name, IPv4 and v6 addresses. You can also:

* as-you-type search from the datatable search box (lowercased and filtered to a normalised MAC address);
* restrict the view to a single VLAN;
* action-to-move to layer 2 address add / edit / delete for a given VLAN interface;
* click on a MAC to bring up a pop-up, allowing you to copy in different formats:

![MAC Address Formats](img/l2a-formats.png)

### Adding / Removing Layer2 Addresses to/from a VLAN Interface

When editing a customer's interface in the usual manner (customer overview -> Ports -> edit button), you will now see a layer2 address under *VLAN Interfaces*:

![MAC Address per VLAN Interface](img/l2a-vlint1.png)

In the event that there is zero or more than one layer2 address, the layer2 address demonstrated above will be replaced with an appropriate note to indicate this.

Clicking on the layer2 address (or note when none  / multiple) will bring you to the layer2 address management page for this VLAN interface. Addresses can be added / removed on this page. Layer2 addresses can be entered in either upper or lower cases and can optionally include characters such as `.`, `:`, `-`. These are all stripped before validation and insertion.

### Extracting Addresses

As automation features are still a work in progress, not all methods are listed here. Please [open an issue on GitHub](https://github.com/inex/IXP-Manager/issues) or start a discussion on the [mailing list](https://www.ixpmanager.org/support.php) for whatever methods you would like.

Currently implemented:

1. A soon to be added API to be used by the sflow / peer to peer graphing tool.
2. YAML export for Salt. As yet undocumented and not suitable for general use.
3. Querying the database directly. *Not usually recommended as the schema may change.*

### Migrating Read-Only to Read/Write

INEX's use case was to switch from the read only *MAC Addresses* table to this table without the need to data fill all preexisting ~200 MACs. As such we have created an Artisan migration script which can be run with:

```sh
php $IXPROOT/artisan l2addresses:populate
```

You will be prompted as follows:

> Are you sure you wish to proceed? This command will CLEAR the layer2address table and then copy addresses from the read-only macaddress table. Generally, this command should only ever be run once when initially populating the new table.

One thing to note: as the *MAC Addresses* table is per virtual interface and the new layer2 address functionality is per VLAN interface, any MAC from *MAC Addresses* that is populated into *Layer2 Addresses* will be populated for every VLAN interface associated with the virtual interface.

The script prints notices for these such as:

> Created >1 layer2address for [member name]] with virtual interface: https://www.example.com/ixp/virtual-interface/edit/id/235

The inclusion of the URL makes it easy to double check the result.

For obvious reasons, we only allow a single / unique layer2 address per VLAN. In the event that the script tries to add the same MAC more than once, it will print:

> Could not add additional instance of 001122334455 for [Customer]] with virtual interface: https://www.example.com/ixp/virtual-interface/edit/id/265 as it already exists in this Vlan [VLAN name]

These should all be checked manually.

A useful SQL command to double check the results for me was:

```sql
SELECT mac, COUNT(mac) AS c FROM l2address GROUP BY mac HAVING COUNT(mac) > 1;
```

## MAC Addresses

This was the original functionality - a read-only table via an admin menu option called *MAC Addresses* which lists entries from a database of MAC addresses which are sourced via a script from the IXP's switches directly.

At an IXP, it can be extremely useful to have a quick look up table to see what member owns what MAC address - especially when they start injecting illegal packets into the exchange fabric.

We have a script, [update-l2database.pl](https://github.com/islandbridgenetworks/IXP-Manager/blob/master/tools/runtime/l2database/update-l2database.pl), for this. To set it up (using Ubuntu as an example=), proceed as below. We are in the process of trying to reduce the reliance on the perl library and direct database access. But for now, this script still requires it.

```sh
# If you haven't already, install the Perl library for IXP Manager:
apt-get install libnet-snmp-perl libconfig-general-perl libnetaddr-ip-perl
cd $IXPROOT/tools/perl-lib/IXPManager
perl Makefile.PL
make install

# Then copy and edit the configuration file to set the database connection settings:
cp $IXPROOT/tools/perl-lib/IXPManager/ixpmanager.conf /usr/local/etc/
joe /usr/local/etc/ixpmanager.conf #and set database settings

# Now copy the script:
cp $IXPROOT/tools/runtime/l2database/update-l2database.pl /usr/local/bin

# and then add it to your periodic cron job with:
/usr/local/bin/update-l2database.pl
```

## OUI Database

IXP Manager can store the IEEE OUI database and reference it to show the manufacturer behind a MAC address.

### Populating and Updating the OUI Database

You would typically set a weekly cron job to call:

```sh
php $IXPROOT/artisan utils:oui-update
```

which will populate / update the OUI database directly from the latest IEEE file from their website.

A specific file can be passed via the `file` parameter. You can also force a database reset (drop all OUI entries and re-populate) via the `--refresh` option.

Neither of these options are typically necessary.
