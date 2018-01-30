# Route Servers

> **Prerequisite Reading:** Ensure you first familiarize yourself with [the generic documentation on managing and generating router configurations here](routers.md).

Normally on a peering exchange, all connected parties will establish bilateral peering relationships with each other customer connected to the exchange. As the number of connected parties increases, it becomes increasingly more difficult to manage peering relationships with customers of the exchange. A typical peering exchange full-mesh eBGP configuration might look something similar to the diagram on the left hand side.

![Route Servers Diagram](img/rs-diagram.png)

The full-mesh BGP session relationship scenario requires that each BGP speaker configure and manage BGP sessions to every other BGP speaker on the exchange. In this example, a full-mesh setup requires 7 BGP sessions per member router, and this increases every time a new member connects to the exchange.

However, by using a route servers for peering relationships, the number of BGP sessions per router stays at two: one for each route server (assuming a resilient set up). Clearly this is a more sustainable way of maintaining IXP peering relationships with a large number of participants.

## Configuration Generation Features

This is [covered in the router documentation here](routers.md). Please review that to learn how to automatically generate route server configurations. This section goes into a bit more specific detail on INEX's route server configuration (as shipped with IXP Manager) and why it's safe to use.

The features of the route server configurations that IXP Manager generates include:

* full prefix filtering based on IRRDB entries (can be disabled on a per member basis if required) - see [the IRRDB documentation here](irrdb.md);
* full origin ASN filtering based on IRRDB entries (can be disabled on a per member basis if required);
* in all cases, prefix filtering for IPv4 and v6 based on the IANA special purpose registries (also known as bogon lists);
* ensuring next hop is the neighbor address to ensure no next hop hijacking;
* max prefix limits;
* multiple VLAN interfaces for a single member supported;
* large BGP communities supported;
* a decade of production use and experience.

There are [some old notes on route server testing here](https://github.com/inex/IXP-Manager/wiki/Route-Server-Testing) which may also be useful.

## Setting Up

You first need to add your route servers to the **IXP Manager** routers database. See [this page on how to do that](routers.md).

Typically an IXP's route server service will have a dedicated ASN that is different to the IXP's own management / route collector ASN. As such, you need to add a new *internal* customer to IXP Manager.

**You are strongly advised to use / request a 16-bit ASN from your RIR for route server use. If you do not, you will be unable to offer your members standard community based filtering.**

Here's an example from INEX for our *route server #1*:

![Route Servers INEX Customer](img/rs-inex-customer.png)

You then need to create an interface for this route server on each peering LAN where the service will be offered. Here again is INEX's example from our peering LAN1 in Dublin:

![Route Servers INEX VLAN Interface Entry](img/rs-inex-vli.png)

There's a couple things to note in the above:

1. *AS112 Client* is checked which means (so long as *Route Server Client* is checked on the [AS112 service](as112.md)) the AS112 service will peer with the route servers.
2. *Apply IRRDB Filtering* has no meaning here as this is the route server rather than the route server client.
