# API &amp; Permissions

This page discusses default permissions required for accessing certain graphs and well as details on how to change that.

## Accessibility of Aggregate Graphs

By default, the following graphs are **publicly** accessible in **IXP Manager** and available through the top menu under *Statistics*:

1. aggregate bits/sec and packets/sec graphs for the IXP;
2. aggregate bits/sec and packets/sec graphs for the infrastructures;
2. aggregate bits/sec and packets/sec graphs for locations / facilities;
3. aggregate bits/sec graphs on a per-protocol and per-VLAN basis (requires [sflow](../features/sflow.md));
4. aggregate graphs for the switches; and
5. aggregate graphs for the core bundles / trunk connections.

If you wish to limit access to these to a *less than or equal* [user permission](../usage/users.md), set the following in `.env` appropriately:

1. `GRAPHER_ACCESS_IXP`
2. `GRAPHER_ACCESS_INFRASTRUCTURE`
3. `GRAPHER_ACCESS_LOCATION`
3. `GRAPHER_ACCESS_VLAN`
4. `GRAPHER_ACCESS_SWITCH`
5. `GRAPHER_ACCESS_TRUNK` *(this also applies to core bundles)*

For example to limit access to trunks / core bundles to logged in users, set:

```
GRAPHER_ACCESS_TRUNK=1
```

If you would like to make the aggregate graphs available to logged in users only, set the following `.env` options:

```
GRAPHER_ACCESS_IXP=1
GRAPHER_ACCESS_INFRASTRUCTURE=1
GRAPHER_ACCESS_VLAN=1
GRAPHER_ACCESS_SWITCH=1
GRAPHER_ACCESS_LOCATION=1
GRAPHER_ACCESS_TRUNK=1
```

If you would prefer to restrict access to these to superusers / admins only, replace `=1` above with `=3`.

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
    "class": "ixp",
    "urls": {
        "png": "https:\/\/www.inex.ie\/ixp\/grapher\/ixp?period=day&type=png&category=bits&protocol=all&id=1",
        "log": "https:\/\/www.inex.ie\/ixp\/grapher\/ixp?period=day&type=log&category=bits&protocol=all&id=1",
        "json": "https:\/\/www.inex.ie\/ixp\/grapher\/ixp?period=day&type=json&category=bits&protocol=all&id=1"
    },
    "base_url": "https:\/\/www.inex.ie\/ixp\/grapher\/ixp",
    "statistics": {
        "totalin": 15013439801606864,
        "totalout": 15013959560329200,
        "curin": 158715231920,
        "curout": 158713872624,
        "averagein": 125566129180.59367,
        "averageout": 125570476225.09074,
        "maxin": 222438012592,
        "maxout": 222348641336
    },
    "params": {
        "type": "json",
        "category": "bits",
        "period": "day",
        "protocol": "all",
        "id": 1
    },
    "supports": {
        "protocols": {
            "all": "all"
        },
        "categories": {
            "bits": "bits",
            "pkts": "pkts"
        },
        "periods": {
            "day": "day",
            "week": "week",
            "month": "month",
            "year": "year"
        },
        "types": {
            "png": "png",
            "log": "log",
            "json": "json"
        }
    },
    "backends": {
        "mrtg": "mrtg"
    },
    "backend": "mrtg"
}
```

You can see from the above what `params` were used to create the `statistics` (and would be used for the image if `type=png`), what parameters are supported (`supports`), what backends are available for the given graph type and mix of parameters, etc.

**Notes:**

1. not all backends support all options or graphs; use the `json` type to see what's supported *but remember that IXP Manager will, when configured correctly, chose the appropriate backend*;
2. the primary key IDs mentioned below are mostly available in the UI when viewing lists of the relevant objects under a column *DB ID*;
3. an understanding of how IXP Manager represents interfaces is required to grasp the below - [see here](../usage/interfaces.md).

Let's first look at supported graphs:

* `ixp`: aggregate graph for an IXP's overall traffic. `id`, which defaults to `1`, is the primary key of the IXP from the `ixp` database table. As **IXP Manager** does not support multiple IXPs, this defaults to `id=1`. [Currently only supported via MRTG for `protocol=all`]


* `infrastructure`: aggregate graph for the overall traffic on a specific IXP infrastructure. For many IXPs, they'll just have a single infrastructure and this will go unused as it would be the equivalent of `ixp` above. `id`, which is mandatory, is the primary key of the infrastructure from the `infrastructure` database table. [Currently only supported via MRTG for `protocol=all`]


* `vlan`: aggregate graph for a specific VLAN. `id`, which is mandatory, is the primary key of the VLAN from the `vlan` database table. [Currently only supported via sflow for `protocol=ipv4|ipv6` and `category=bits|pkts`]


* `location`: aggregate graph of all peering traffic being switched by a specific facility (sum of all customer ports **not including** core ports). `id`, which is mandatory, is the primary key of the location / facility from the `location` database table. [Currently only supported via MRTG for `protocol=all`]. *Note that we are looking at all traffic originating and/or terminating at a location rather than traffic passing through it.

* `switch`: aggregate graph of all peering traffic being switched by a specific switch (sum of all customer ports plus core ports). `id`, which is mandatory, is the primary key of the switch from the `switch` database table. [Currently only supported via MRTG for `protocol=all`]

* `core-bundle`: inter-switch / trunk graphs configured in IXP Manager using the *Core Bundles* tool. The `id` is mandatory and is the database ID of the core bundle. An additional parameter is supported also: `&side=a` or `&side=b` which determines which side of the core bundle you want to graph. This parameter is optional and defaults to `a`. Each side of the graph will be about identical (only differing by MRTG polling time) but with tx/rx reversed. Access is determined using the `GRAPHER_ACCESS_TRUNK`.

* `trunk`: a legacy hold over from *Inter-Switch / Trunk Graphs* above to be replaced with core bundles.

* `physicalinterface`: traffic for an individual member port - a single physical switch port. `id`, which is mandatory, is the primary key of the physical interface from the `physicalinterface` database table. [Currently only supported via MRTG for `protocol=all`]


* `virtualinterface`: if a member has a single connection (one switch port) then this is the same as `physicalinterface` above. However, if they have a LAG port then it's the aggregate traffic for all physical ports in the LAG. `id`, which is mandatory, is the primary key of the virtual interface from the `virtualinterface` database table. [Currently only supported via MRTG for `protocol=all`]


* `customer`: the aggregate traffic for all ports belonging to a customer across all infrastructures. `id`, which is mandatory, is the primary key of the customer from the `cust` database table. [Currently only supported via MRTG for `protocol=all`]


* `vlaninterface`: aggregate traffic flowing through a members VLAN interface for a specific protocol. `id`, which is mandatory, is the primary key of the VLAN interface from the `vlaninterface` database table. [Currently only supported via sflow for `protocol=ipv4|ipv6`]

* `latency`: latency graphs (e.g. Smokeping). `id`, which is mandatory, is the primary key of the VLAN interface from the `vlaninterface` database table. `protocol=ipv4|ipv6` is also mandatory. Periods for Smokeping are different to the default periods and should be one of `3hours|30hours|10days|1year`.

* `p2p`: peer to peer traffic between two member VLAN interfaces. The source (`svli`) and destination (`dvli`) VLAN interface IDs are required. `svli` and `dvli`, which are mandatory, are primary keys of the VLAN interfaces from the `vlaninterface` database table. [Currently only supported via sflow for `protocol=ipv4|ipv6`]


For additional options, it's always best to manually or programmatically examine the output for `type=json` to see what is supported. The following is a general list.

* `type`: one of:

    * `json` - as demonstrated and described above;
    * `log` - MRTG  log file type output formatted as a JSON array;
    * `rrd` - the RRD file for the requested graph type;
    * `png` - the graph image itself (default).
    * potentially others as supported / implemented by newer backends.



* `period`: one of `day`, `week`, `month`, `year` (except for `latency` graphs as described above).


* `category`: one of `bits`, `pkts` (packets), `errs` (errors), `discs` (discards), `bcasts` (broadcasts). Bits is measured in bits per second, the rest in packets per second.


* `protocol`: one of `all`, `ipv4` or `ipv6`.


* `backend`: default is to let IXP Manager decide.


## Access Control

The grapher API can be accessed using the [standard API access mechanisms](../features/api.md).

Each graph (ixp, infrastructure, etc.) has an `authorise()` method which determines who is allowed view a graph. For example, see [IXP\Services\Grapher\Graph\VlanInterface::authorise()](https://github.com/inex/IXP-Manager/blob/master/app/Services/Grapher/Graph/VlanInterface.php#L131). The general logic is:

* if the graph is configured to be publicly accessible -> allow
* if not logged in / no valid API key -> deny
* if superuser -> allow
* if user belongs to customer graph requested -> allow
* otherwise -> deny and log

For the supported graph types, default access control is:

Graph               |  Default Access Control
--------------------|----------------------------------
`ixp`               | public but respects `GRAPHER_ACCESS_IXP` (see above)
`infrastructure`    | public but respects `GRAPHER_ACCESS_INFRASTRUCTURE` (see above)
`vlan`              | public but respects `GRAPHER_ACCESS_VLAN` (see above), unless it's a private VLAN (in which case only superuser is supported currently)
`location`          | public but respects `GRAPHER_ACCESS_LOCATION` (see above)
`switch`            | public but respects `GRAPHER_ACCESS_SWITCH` (see above)
`core-bundle`       | public but respects `GRAPHER_ACCESS_TRUNK` (see above)
`trunk`             | public but respects `GRAPHER_ACCESS_TRUNK` (see above)
`physicalinterface` | superuser or user of the owning customer but respects `GRAPHER_ACCESS_CUSTOMER` (see *Access to Member Graphs* below)
`vlaninterface`     | superuser or user of the owning customer but respects `GRAPHER_ACCESS_CUSTOMER` (see *Access to Member Graphs* below)
`virtualinterface`  | superuser or user of the owning customer but respects `GRAPHER_ACCESS_CUSTOMER` (see *Access to Member Graphs* below)
`customer`          | superuser or user of the owning customer but respects `GRAPHER_ACCESS_CUSTOMER` (see *Access to Member Graphs* below)
`latency`           | superuser or user of the owning customer but respects `GRAPHER_ACCESS_LATENCY` (see *Access to Member Graphs* below)
`p2p`               | superuser or user of the source (`svli`) owning customer but respects `GRAPHER_ACCESS_P2P` (see *Access to Member Graphs* below)



### Access to Member Graphs

**NB: before you read this section, please first read and be familiar with the *Accessibility of Aggregate Graphs* section above.**

A number of IXPs have requested a feature to allow public access to member / customer graphs. To support this we have added the following `.env` options (beginning in v4.8) with the default value as shown:

```
GRAPHER_ACCESS_CUSTOMER="own_graphs_only"
GRAPHER_ACCESS_P2P="own_graphs_only"
GRAPHER_ACCESS_LATENCY="own_graphs_only"
```

The `own_graphs_only` setting just means *perform the default access checks* which are: access is granted to a superuser or a user who belongs to the customer which owns the respective graph. I.e. no one but the customer or a superadmin can access the respective graph.

If you wish to allow access to these to a *less than or equal* [user permission](../usage/users.md), set the above in `.env` appropriately.

For example:

* to allow public access to all customer graphs (customer aggregate, LAG aggregates, physical interfaces and per-VLAN/protocol graphs);
* to allow any logged in customer access any other customer's peer to peer graphs; and
* to continue to restrict latency graph access to superadmins and the owning customer

then set the following in `.env`:

```
GRAPHER_ACCESS_CUSTOMER=0
GRAPHER_ACCESS_P2P=1
```

*Note that `GRAPHER_ACCESS_LATENCY` is omitted as we are not changing the default.*

Please note the following:

* `GRAPHER_ACCESS_CUSTOMER` applies to customer aggregate graphs, customer LAG graphs (virtualinterface), customer ports (physicalinterface) and customer vlaninterface. T individually limit these makes little sense and drastically increases complexity (from a UI perspectve).
* It makes limited sense for UI access to enable either `GRAPHER_ACCESS_P2P` or `GRAPHER_ACCESS_LATENCY` without enabling equivalent or less restrictive access to `GRAPHER_ACCESS_CUSTOMER`. This is because most of the user interface (UI) pathways to access these is via `GRAPHER_ACCESS_CUSTOMER` pages.
