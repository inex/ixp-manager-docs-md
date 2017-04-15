# Reseller Functionality

Reseller mode must be explicitly enabled with a `.env` option:

```
IXP_RESELLER_ENABLED=true
```

## Introduction


In our model, a *resold* member is still a fully fledged member, they just happen to reach the exchange via someone else's network. You / we would still have a relationship with the member independent of the reseller and would still be required to carry out the standard turn up (for us, this includes IP assignment, quarantine procedures, route collector session, route server sessions if appropriate, etc.).

IXP Manager's functionality is simply to:

 - record that a reseller relationship exists
 - allow you to manage reseller and fanout ports

## Features

- A customer / member can now also be a reseller. If you have a non-customer reseller, create them as an associate or internal member as appropriate. This is a boolean switch available in the add / edit customer page.
- Any customer can be marked as a *resold customer of a named reseller*. This is set in the add / edit customer page.
- If a customer is a reseller or a resold customer, this is clearly visible in the customer overview page.
- A reseller cannot be *demoted* from reseller status while there are resold customers assigned to it.
- In the reseller customer overview page, there is a new tab listing all the customers they have resold to the IXP.
- In the reseller customer overview page, the ports are separated into reseller uplink ports, the reseller's own peering ports and the fanout ports used to deliver the reseller's customers' traffic.

### Reseller and Fanout Ports.

For resellers, we need to enforce the **one port - one mac - one address** rule on the peering LAN.

Depending on switch technology, this can be done using

* a virtual ethernet port; or
* a dedicated fanout switch / port.

> Currently the schema cannot adequately handle a virtual ethernet port.

Typically, we'd assign a dedicated switch (or bunch of switch ports) as a *fanout* switch with a *reseller uplink port* (or LAG). The reseller delivers their customer traffic in dedicated VLANs over this uplink port. We then break each individual customer's traffic into dedicated *fanout ports*. These physical fanout ports have a one to one relationship with peering ports for that customer (these can be single physical ports or LAGs).

The reseller functionality includes:

* new switch port types for *reseller* (reseller uplink ports) and *fanout*;
* a clear 1:1 relationship between peering ports that come via fanout ports;
* a reseller has all their peering, reseller uplink and associated fanout ports listed in their overview and portal page;
* the add physical interface form and the add interface wizard support linking a peering port to a new fanout port as part of the process.



## Options

The following are set in `.env`:

To enable reseller functionality, set the following to `true`:

```
IXP_RESELLER_ENABLED=false
```

If your resold customers are billed directly by the reseller and not the IXP, set this to true to remove billing details from their admin and member areas.

```
IXP_RESELLER_RESOLD_BILLING=false
```

## Coding Hints

In the (older Zend Framework) controllers, you can execute reseller code via:

```php
if( $this->resellerMode() ) {
    // your reseller specific code here
}
```

And in (the older Zend Framework) Smarty templates, you can add reseller only content via:

```
{if $resellerMode}
    <!-- Your reseller content -->
{/if}
```

If you have a `$customer` entity, you can see if it is a reseller via:

```php
if( $customer->isReseller() ) {}
```

To see if a customer is a resold customer or get the reseller customer entity:

```php
if( $customer->getReseller() ) {} // returns false if not a resold customer
```

Finally, to get all resold customer entities of a reseller:

```php
$customer->getResoldCustomers()
```

-----------------------

Reseller functionality was added jointly by [INEX](https://www.inex.ie/) and [LONAP](http://www.lonap.net/) in June 2013.
