# Routers

**Note that a number of pages redirect here where we have collated documentation on route collectors, route servers, AS112 servcies and IRRDB filtering.**

IXP Manager can generate router configuration for typical IXP services such as route collectors, route servers and AS112 services. How this is done has been changed significantly from v3 to v4.

> Note that until officially deprecated, the older v3 methods still work and the [official v3 documentation](https://github.com/inex/IXP-Manager/wiki) should be referenced for that.

## Configuration Overview

The basic elements of *a router* are configured in `configs/routers.php`. This is an optional file that is not included in version control so the best way to start it is to copy from the template:

```
cp config/routers.php.dist config/routers.php
```

A typical entry of a sample router (in standard PHP associative array syntax) is:

```php
<?php
    'rc1-lan1-ipv4' => [
        'vlan_id'    => 1,
        'protocol'   => 4,
        'type'       => 'RC',   // RC|RS|AS112?
        'name'       => 'INEX LAN1 - Route Collector - IPv4',
        'shortname'  => 'RC1 - LAN1 - IPv4',
        'router_id'  => '192.0.2.8',
        'peering_ip' => '192.0.2.8',
        'asn'        => 65500,
        'software'   => 'bird',
        'mgmt_ip'    => '203.0.113.8',
        'api'        => 'http://rc1-lan1-ipv4.mgmt.example.com/api',
        'api_type'   => 'birdseye',
        'lg_access'  => Entities\User::AUTH_PUBLIC,
        'quarantine' => false,
        'bgp_lc'     => false,
        'template'   => 'api/v4/router/collector/bird/standard',
    ],
```

where:

* `rc1-lan1-ipv4` is the **handle** for this router to be used in API calls later (it's the key of the PHP associative array).
* `vlan_id` is not the VLAN 802.1q tag number but the `vlan.id` database column. You can get this, for example, by hovering over the edit action in the VLAN listing in IXP Manager and finding the number in the URL.
* `protocol` is either `4` (IPv4) or `6` (IPv6). Any other value will lead to a runtime exception.
* we have currently defined three types which are used for grouping routers in the UI and for other selection purposes:
  * `RC` - route collector;
  * `RS` - route server;
  * `AS112` - an AS112 BGP peer (see [INEX's AS112 documentation](https://www.inex.ie/technical/as112-service/) as an example).
* `name` - name / description of the router's purpose.
* `shortname` - used in dropdowns or other space constrained areas where `name` may be too long.
* `router_id` - the router's BGP ID (e.g. `192.0.2.8`).
* `peering_ip` - the IPv4/6 address that this router initiates BGP peering sessions from.
* `asn` - the router's AS number.
* `software` - there is no specific use for this as yet.
* `mgmt_ip` - the IP to address this server / router at for management functions such as Nagios monitoring.
* `api` and `api_type` - the API end point for this server/router. The only use case for this so far is for the built-in [looking glass](looking-glass.md) functionality via [Birdseye](https://github.com/inex/birdseye).
* `lg_access` - who should be allow access the looking glass. One of:
  * `AUTH_PUBLIC` - publicly available to all;
  * `AUTH_CUSTUSER` - must be logged into IXP Manager as any user;
  * `AUTH_SUPERUSER` - must be logged into IXP Manager as an administrator (no customer access).
* `quarantine` - a flag to indicate if this router is part of the IXP's quarantine / test infrastructure. For example, INEX runs two parallel route collectors: one quarantine and one production. When customers have issues or are being provisioned, they are placed in the quarantine LAN and we can examine BGP announcements safely on the non-production quarantine devices. When a router is marked as quarantine, it is only visible in looking glass dropdowns to customers who also have a port in quarantine (physical interface status).
* `bgp_lc` - a flag to indicate if the router supports [RFC8092](https://tools.ietf.org/html/rfc8092) / [large BGP communities](http://largebgpcommunities.net/).
* `template` - the template to use to generate the configuration. See stock examples [here](https://github.com/inex/IXP-Manager/tree/master/resources/views/api/v4/router) (and note that [skinning](skinning.md) is supported).

Typically your `routers.php` file would hold multiple such entries. It is our intention to move this into the UI and database.

## Examples

We use Travis CI to test IXP Manager before making new releases. The primary purpose of this is to ensure that the configuration for routers generated matches known good configurations from the same sample database.

These know good configurations also serve as useful examples of what the standard IXP Manager configuration generates.

See [these known good configurations here](https://github.com/inex/IXP-Manager/tree/master/data/travis-ci/known-good) with the prefix `ci-apiv4-` and:

* `as112`: AS112 router configurations conforming to [rfc7534](https://tools.ietf.org/html/rfc7534) (AS112 Nameserver Operations) and implementing [rfc7535](https://tools.ietf.org/html/rfc7535) (AS112 Redirection Using DNAME). There are configs to serve queries over both IPv4 and IPv6.
* `rc1`: route collector configurations. Peering with the route collector is mandatory at many IXPs including INEX. These are incredably useful for monitoring, diagnosing issues and providing looking glasses. We also use the quarantine version of these for turning up new member connections.
* `rs1`: route collector configurations. See below for full details of what these implement. Note also that the `ci-apiv4-rs1-lan2-ipv4.conf` file includes BGP large communities ([rfc8092](https://tools.ietf.org/html/rfc8092)).


## Generation Overview

The simplest configuration to generate is the route collector configuration. A route collector is an IXP router which serves only to *accept all routes and export no routes*. It is used for problem diagnosis, to aid customer monitoring and for looking glasses (see [INEX's here](https://www.inex.ie/ixp/lg/rc1-lan1-ipv4).

The [standard configuration](https://github.com/inex/IXP-Manager/blob/master/resources/views/api/v4/router/collector/bird/standard.foil.php) simply pulls in a fairly standard header (sets up router ID, listening address and - for the collector at least - some unused filters) and creates a session for all customer routers on the given VLAN (see `vlan_id` above).

In the above example, the route handle is the array's associative key (`rc1-lan1-ipv4`) and - for the given router handle - the configuration can be generated via:

```
# The key is generated in IXP Manager via the top right menu: *My Account -> API Keys*
KEY="your-admin-ixp-manager-api-key"
# The base URL of your IXP Manager install plus: 'api/v4/router/gen_config'
URL="https://ixp.example.com/api/v4/router/gen_config"
# The handle is the PHP associative key from `config/routers.php` as described above
HANDLE="rc1-lan1-ipv4"
# Then the complete URL is formed as:
curl --fail -s -H "X-IXP-Manager-API-Key: ${KEY}" ${URL}/${HANDLE} >${HANDLE}.conf
```

Configurations for the route server and AS112 templates can be configured just as easily. The stock templates for both are secure and well tested and can be used by setting the `template` element of the router configuration above to the following:

* AS112: `'api/v4/router/as112/bird/standard'`
* Route Server: `'api/v4/router/server/bird/standard'`

We also provide sample scripts for automating the re-configuration of these services by cron. See the `-v4` scripts [in this directory](https://github.com/inex/IXP-Manager/tree/master/tools/runtime/route-servers). These are quite robust and have been in production for ~3 years at INEX (as of Jan 2017).

## Route Servers

Normally on a peering exchange, all connected parties will establish bilateral peering relationships with each other customer connected to the exchange. As the number of connected parties increases, it becomes increasingly more difficult to manage peering relationships with customers of the exchange.

However, by using a route servers for peering relationships, the number of BGP sessions per router stays at two: one for each route server (assuming a resilient set up). Clearly this is a more sustainable way of maintaining IXP peering relationships with a large number of participants.

You will have learnt above how to automatically generate route server configurations. This section goes into a bit more specific detail on INEX's route server configuration (shipped with IXP Manager) and why it's safe to use.

The features of the route server configurations that we generate include:

* full prefix filtering based on IRRDB entries (can be disabled on a per member basis if required);
* full origin ASN filtering based on IRRDB entries (can be disabled on a per member basis if required);
* in all cases, prefix filtering for IPv4 and v6 based on the IANA special purpose registries (also known as bogon lists);
* ensuring next hop is the neighbor address to ensure no next hop hijacking;
* max prefix limits;
* multiple VLAN interfaces for a single member supported;
* large BGP communities supported;
* a decade of production use and experience.

There are [some old notes on route server testing here](https://github.com/inex/IXP-Manager/wiki/Route-Server-Testing) which may also be useful.

## IRRDB Prefixes and ASN Filtering

IXP Manager can maintain a list of member route:/route6: prefixes and origin ASNs as registered in IRRDBs in its database and then use these to, for example, generate strict inbound filters on route servers.

**Prerequisite:** you need to have set up some IRRDB sources (e.g. RIPE's whois service) under the *IXP Admin Actions / IRRDB Configuration* on the left hand side menu. There is a database seeder to install some to start you off via the following (but thius is typically done during installation):

```
./artisan db:seed --class=IRRDBs
```

BGPQ3 is a very easy and fast way of querying IRRDBs. You first need to install this on your system. Then configure the path to it in `config/ixp_tools.php`. If you have not used this file before, you'll need to create your own local copy as follows:

```
cp config/config/ixp_tools.php.dist config/config/ixp_tools.php
```

Then set the full call path for ``bgpq3`` in this file:

```php
<?php

  'irrdb' => [
        'bgpq' => [
            'path' => '/path/to/bgpq3',
        ],
    ],
```

To populate (and update) your local IRRDB, run the following commands (changing the path as appropriate):

```
/srv/ixpmanager/artisan irrdb:update-prefix-db
/srv/ixpmanager/artisan irrdb:update-asn-db
```

These should be added to cron to run ~once per day (using the --quiet flag).

There are four levels of verbosity:

1. `-quiet`: no output unless there's an error / issue.
2. no option: simple stats on each customer's update results.
3. `-vv`: include per customer and overall timings (database, processing and network).
4. `-vvv` (debug): show prefixes/ASNs added remove also.

You can also specify a specific customer to update (rather than all) with an additional free form parameter. The database is searched for a matching customer in the order: customer ASN; customer ID (database primary key); and customer shortname. E.g.:

```
/srv/ixpmanager/artisan irrdb:update-prefix-db 64511
```

The IRRDB update commands will:

* iterate over all route server client customers for IPv4 and IPv6 (unless a specific customer is specified);
* use the appropriate AS macro or ASN;
* query the RADB against the appropriate source set for that customer;
* compare prefixes(/ASNs) in the database already (if any) against RADB and insert / delete as appropriate;
* validate the prefix for proper CIDR notation before database inserts;
* update the last_seen time for all prefixes(/ASNs) for that customer;

**We use transactions to update the database so, even in the middle of a refresh, a full set of prefixes for all customers will still be available.**

*Note that our current implementation only queries RADB as BGPQ3 does not support the RIPE whois protocol.* Our version will however set the RADB source database according to the member's stated IRRDB database as set on the customer add / edit page - so, for customer's registered with the RIPE IRRDB, the RIPE database of RADB is queried.
