# API &amp; Permissions

This page discusses default permissions required for accessing certain graphs and well as details on how to change that.

## Accessibility of Aggregate Graphs

By default, the following graphs are **publically** accessible in **IXP Manager** and available through the top menu under *Statistics*:

1. aggregate bits and packets graphs for the IXP;
2. aggregate bits and packets graphs for the infrastructures;
3. aggregate graphs for the switches; and
4. aggregate graphs for the trunk connections.

If you wish to limit access to these to a *less than or equal* [user permission](../usage/users.md), set the following in `.env` appropriately:

1. `GRAPHER_ACCESS_IXP`
2. `GRAPHER_ACCESS_INFRASTRUCTURE`
3. `GRAPHER_ACCESS_SWITCH`
4. `GRAPHER_ACCESS_TRUNK`

For example to limit `GRAPHER_ACCESS_TRUNK` to logged in users, set:

```
GRAPHER_ACCESS_TRUNK=1
```

*The older Zend Framework templates will still show these options in the menu but these templates are being aggressively phased out.*

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


### API Access Control

The grapher API can be accessed using the [standard API access mechanisms](../features/api.md).

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
`latency`           | superuser or user of the owning customer
`p2p`               | superuser or user of the source (`svli`) owning customer
