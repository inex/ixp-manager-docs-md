# IRRDB Prefixes and ASN Filtering

> **Prerequisite Reading:** Ensure you first familiarize yourself with [the generic documentation on managing and generating router configurations here](routers.md).

IXP Manager can maintain a list of member route:/route6: prefixes and origin ASNs as registered in IRRDBs in its database and then use these to, for example, generate strict inbound filters on route servers.

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

Then configure the path to it in your `.env` file.

```php
# Absolute path to run the bgpq3 utility
# e.g. IXP_IRRDB_BGPQ3_PATH=/usr/local/bin/bgpq3
IXP_IRRDB_BGPQ3_PATH=/usr/bin/bgpq3
```

## Usage

To populate (and update) your local IRRDB, run the following commands:

```
cd $IXPROOT
php artisan irrdb:update-prefix-db
php artisan irrdb:update-asn-db
```

From IXP Manager v5 onwards, and so long as your bgpq3 path is set as above and is executable, the [task scheduler](cronjobs.md) will take care of updating your local IRRDB a number of times a day. If you are using a version of IXP Manager before v5, then the above commands should be added to cron to run ~once per day (using the --quiet flag).

There are four levels of verbosity:

1. `--quiet`: no output unless there's an error / issue.
2. no option: simple stats on each customer's update results.
3. `-vv`: include per customer and overall timings (database, processing and network).
4. `-vvv` (debug): show prefixes/ASNs added remove also.

You can also specify a specific customer to update (rather than all) with an additional free form parameter. The database is searched for a matching customer in the order: customer ASN; customer ID (database primary key); and customer shortname. E.g.:

```sh
php artisan irrdb:update-prefix-db 64511
```

### Internal Workings

Essentially, based on a customers AS number / IPv4/6 Peering Macro, IXP Manager [uses bgpq3](https://github.com/snar/bgpq3) to query IRRDBs as follows:

```bash
bgpq3 -S $sources -l pl -j [-6] $asn/macro
```

where `$sources` come from the IRRDB sources entries.

Or, a real example:

```bash
bgpq3 -S RIPE -l pl -j AS-BTIRE
bgpq3 -S RIPE -l pl -j -6 AS-BTIRE
```


## Details

The IRRDB update commands will:

* iterate over all route server client customers for IPv4 and IPv6 (unless a specific customer is specified);
* use the appropriate AS macro or ASN;
* query the RADB against the appropriate source set for that customer;
* compare prefixes(/ASNs) in the database already (if any) against RADB and insert / delete as appropriate;
* validate the prefix for proper CIDR notation before database inserts;
* update the last_seen time for all prefixes(/ASNs) for that customer;
* create a local file-based cache of that customer's prefixes / asns to speed up router configuration generation *(you don't need to worry about the staleness of this cache as it's cached everytime the IRRDB commands above are run for each customer)*.

**We use transactions to update the database so, even in the middle of a refresh, a full set of prefixes for all customers will still be available.** It also means the update process can be safely interrupted.

**Note that our current implementation only queries RADB as BGPQ3 does not support the RIPE whois protocol.** Our version will however set the RADB source database according to the member's stated IRRDB database as set on the customer add / edit page - so, for customer's registered with the RIPE IRRDB, the RIPE database of RADB is queried.
