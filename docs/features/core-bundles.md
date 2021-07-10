# Core Bundles

A *core bundle* is a link between the IXP's own switches. These are often referred to as *trunks*, *interswitch links (ISLs)*, *core links*, etc. **IXP Manager** has a number of features to support these since v6 was released.

Before continuing with this document, it is critical you have read and understand how IXP Manager represents normal member connections - please read the [Customer Connections](../usage/interfaces.md) page before proceeding as the rest of this document assumes that foundational knowledge.

Within IXP Manager, a *core bundle* represents a link(s) between two switches. This bundle may have one or more links and it may be one of three types:

1. A layer 2 LACP link *(L2-LAG)*. Where your exchange has more than two switches, a protocol such as spanning tree would operate across these links to prevent loops.

    If you are running just two switches with a single link between them, this is also the option you would choose. We'd typically recommend a protocol such as LACP or UDLD runs across even single links to detect unidirectional link errors.

2. A layer 3 LAG *(L3-LAG)* is for one or more aggregated links between a switch when using a routed underlay such as MPLS / VPLS / VXLAN. Each end of the link would have an IP address and participate in a routing core network.

3. *ECMP* is similar to L3-LAG above each each individual link in the *core bundle* has its own IP addressing and traffic distribution across the links is handled via equal-cost multi-path (ECMP) routing.

???+ important "INEX has been using the core bundles feature internally for some time without issue. We use ECMP extensively and L2-LAGs to a lesser extent. This all ties into our automation. L3-LAGs are mostly untested by us so please open bug reports on GitHub if there are any issues."


## Database Representation

To fully understand IXP Managers implementation of core bundles, it is important to have an awareness of the database representation of them. This is why reading the [customer connections](../usage/interfaces.md) page is important - core bundles have been designed to fit into the existing database representation:

![Core Bundles - Database Objects](img/core-bundles-db.png)

As you'll note, we still have a virtual interface (VI) as the syntactic sugar to represent a link where:

* Each VI is owned by a customer. In the case of core bundles, the *customer* will be your IXP's internal customer record.
* VIs contain one or more physical interfaces (PIs). As you'll note from the second representation below, each PI has a one-to-one relationship with a switch port (SP).

What's new is we've added a new element of syntactic sugar - the core bundle (CB) - and this is used to group the two ends of the link(s) between switches together.

![Core Bundles - Database Objects](img/core-bundles-db2.png)

* Each CB has one or more pairs of core links (CLs).
* Each core link represents a physical connection (e.g. the fibre cable) from a port on one switch to the port on another switch.
* Each core link has two core interfaces (CIs) - the 'a side' interface and the 'b side' interface.
  * Which switch is the 'a side' doesn't matter as long as it is consistent for each core link in a core bundle. I.e. if a core bundle has four links, then the same switch must be the 'a side' for each core interface.
* A core interface (CI) is a simple one-to-one mapping to a physical interface. From there, the existing schema takes over and a physical interface connects to a switch port which in turn is attached to a switch.

> The above may seem quite complex but it works well in practice. Most importantly, IXP Manager guides you through most of the complexity when setting up and managing core bundles. However, it's still important to have a grasp of the above as the user interface does reflect the underlying database schema.
