# IRRDB Prefixes and ASN Filtering

> **Prerequisite Reading:** Ensure you first familiarize yourself with [the generic documentation on managing and generating router configurations here](routers.md).

IXP Manager can maintain a list of member route:/route6: prefixes and origin ASNs as registered in IRRDBs in its database and then use these to, for example, generate strict inbound filters on route servers.

## Setup

You need to have set up some IRRDB sources (e.g. RIPE's whois service) under the *IXP Admin Actions / IRRDB Configuration* on the left hand side menu. If this wasn't done as part of an upgrade from v3 / your initial installation then there is a database seeder you can use to install some to start you off:

```sh
cd $IXPROOT
./artisan db:seed --class=IRRDBs
```

[BGPQ3](https://github.com/snar/bgpq3) is a very easy and fast way of querying IRRDBs. You first need to install this on your system. On Ubuntu 16.04 this is as easy as:

```sh
apt install bgpq3
```

Then configure the path to it in `config/ixp_tools.php`. If you have not used this file before, you'll need to create your own local copy as follows:

```sh
cp config/config/ixp_tools.php.dist config/config/ixp_tools.php
```

Then set the full call path for `bgpq3` in this file:

```php
<?php

  'irrdb' => [
        'bgpq' => [
            'path' => '/path/to/bgpq3',
        ],
    ],
```

## Usage

To populate (and update) your local IRRDB, run the following commands:

```
cd $IXPROOT
php artisan irrdb:update-prefix-db
php artisan irrdb:update-asn-db
```

These should be added to cron to run ~once per day (using the --quiet flag).

There are four levels of verbosity:

1. `--quiet`: no output unless there's an error / issue.
2. no option: simple stats on each customer's update results.
3. `-vv`: include per customer and overall timings (database, processing and network).
4. `-vvv` (debug): show prefixes/ASNs added remove also.

You can also specify a specific customer to update (rather than all) with an additional free form parameter. The database is searched for a matching customer in the order: customer ASN; customer ID (database primary key); and customer shortname. E.g.:

```sh
php artisan irrdb:update-prefix-db 64511
```

## Details

The IRRDB update commands will:

* iterate over all route server client customers for IPv4 and IPv6 (unless a specific customer is specified);
* use the appropriate AS macro or ASN;
* query the RADB against the appropriate source set for that customer;
* compare prefixes(/ASNs) in the database already (if any) against RADB and insert / delete as appropriate;
* validate the prefix for proper CIDR notation before database inserts;
* update the last_seen time for all prefixes(/ASNs) for that customer;

**We use transactions to update the database so, even in the middle of a refresh, a full set of prefixes for all customers will still be available.** It also means the update process can be safely interrupted.

*Note that our current implementation only queries RADB as BGPQ3 does not support the RIPE whois protocol.* Our version will however set the RADB source database according to the member's stated IRRDB database as set on the customer add / edit page - so, for customer's registered with the RIPE IRRDB, the RIPE database of RADB is queried.
