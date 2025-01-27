# IRRDB Prefixes and ASN Filtering

> **Prerequisite Reading:** Ensure you first familiarize yourself with [the generic documentation on managing and generating router configurations here](routers.md).

IXP Manager can maintain a list of member route:/route6: prefixes and origin ASNs as registered in IRRDBs in its database and then use these to, for example, generate strict inbound filters on route servers.

It is important to note that IRRDB database entries are only kept for members who are enabled to use the route servers (option under VLAN interfaces) and have IRRDB prefix filtering enabled (also an option under VLAN interfaces). 

## Setup

You need to have set up some IRRDB sources (e.g. RIPE's whois service) under the *IXP Admin Actions / IRRDB Configuration* on the left hand side menu. If you do not have any entries here, there is a database seeder you can use to install some to start you off:

```sh
cd $IXPROOT
./artisan db:seed --class=IRRDBs
```

[BGPQ3](https://github.com/snar/bgpq3) is a very easy and fast way of querying IRRDBs. You first need to install this on your system. On a modern Ubuntu system this is as easy as:

```sh
apt install bgpq3
```

Then configure the path to it in your `.env` file or via the *Settings* page in IXP Manager.

```
# Absolute path to run the bgpq3 utility
# e.g. IXP_IRRDB_BGPQ3_PATH=/usr/local/bin/bgpq3
IXP_IRRDB_BGPQ3_PATH=/usr/bin/bgpq3
```

There are two other possible options which are defaulted as follows:

```
IXP_IRRDB_MIN_V4_SUBNET_SIZE=24
IXP_IRRDB_MIN_V6_SUBNET_SIZE=48
```

It would be *exceptionally unusual* to change these and this can only be done by setting them in the `.env` file.


## Usage

To manually populate (or update) your local IRRDB database entries, run the following commands:

```
cd $IXPROOT
php artisan irrdb:update-prefix-db
php artisan irrdb:update-asn-db
```

So long as your bgpq3 path is set as above and is executable, the [task scheduler](cronjobs.md) will take care of updating your local IRRDB a number of times a day.

When running the commands manually, there are four levels of verbosity:

1. `--quiet`: no output unless there's an error / issue (used by the task scheduler).
2. no option: simple stats on each customer's update results.
3. `-vv`: include per customer and overall timings (database, processing and network).
4. `-vvv` (debug): show prefixes/ASNs added remove also.

You can also specify a specific customer to update (rather than all) with additional parameters:

```sh
# Update just customer with AS number  64511
php artisan irrdb:update-prefix-db --asn 64511

# Update just customer with database ID 27
php artisan irrdb:update-prefix-db --id 27
```

### Handling Failure

If the automated updates via the task scheduler fail for any member, that member will be skipped and the task will continue to the next member.

On such a failure, an error will be printed which your cron system should capture and email.


## User Interface Features

The status of a members IRRDB entries can be found and updated in various frontend features:

1. A summary of all members' IRRDB database entries / status can be found under the *IRRDB Summary* menu. This will highlight any members where there have never been an IRRDB update (usually new members or members where the process has failed); it will also highlight as *stale* any member who has not had their entries updated in the last 24 hours.
2. On a member's overview page, the last time they have been updated is also shown.
3. Using the diagnostics functionality, a members IRRDB entry status can be checked.
4. You can click through from a number of places to view and update a member's IRRDB entries:
   * Via the summary page above in (1);
   * Via the IRRDB information on the member's overview page in (2); and
   * Via a menu option on the member's overview page.

## Details

The IRRDB update commands will:

* iterate over all route server client customers for IPv4 and IPv6 (unless a specific customer is specified);
* use the appropriate AS macro or ASN;
* query the RADB against the appropriate source set for that customer;
* compare prefixes(/ASNs) in the database already (if any) against RADB and insert / delete as appropriate;
* validate the prefix for proper CIDR notation before database inserts;
* update the last_seen time for all prefixes(/ASNs) for that customer;
* create a local file-based cache of that customer's prefixes / asns to speed up router configuration generation *(you don't need to worry about the staleness of this cache as it's cached everytime the IRRDB commands above are run for each customer)*.

**We use database transactions to update the database so, even in the middle of a refresh, a full set of prefixes for all customers will still be available.** It also means the update process can be safely interrupted.

**Note that our current implementation only queries RADB as BGPQ3 does not support the RIPE whois protocol.** Our version will however set the RADB source database according to the member's stated IRRDB database as set on the customer add / edit page - so, for customer's registered with the RIPE IRRDB, the RIPE database of RADB is queried.




### Internal Workings

Based on a customers AS number / IPv4/6 Peering Macro, IXP Manager [uses bgpq3](https://github.com/snar/bgpq3) to query IRRDBs as follows:

```bash
bgpq3 -S $sources -l pl -j -m $min_subnet_size [-6] $asn/macro
```

where `$sources` come from the IRRDB sources entries and `$min_subnet_size` is explained above.

Or, a real example:

```bash
bgpq3 -S RIPE -l pl -j -m 24 AS-BTIRE
bgpq3 -S RIPE -l pl -j -m 48 -6 AS-BTIRE
```

