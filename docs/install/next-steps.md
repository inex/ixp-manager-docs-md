# Post-Install / Next Steps

So you have installed IXP Manager, congratulations! But now you are wondering what to do next?

Hopefully this document will point you in the right direction to help you start using IXP Manager. Note that we assume you have used the [automated installer](automated-script.md) and so you have a single customer already in the database - the IXP's own customer.

## Essential Steps - Set Up the IXP

**We created a video tutorial demonstrating these steps.** You can find the [video here](https://www.youtube.com/watch?v=Cuox538kFZs) in our [YouTube channel](https://www.youtube.com/channel/UCeW2fmMTBtE4fnlmg-2-evA). As always, [the full catalog of video tutorials is here](https://www.ixpmanager.org/support/tutorials).


There are basic elements you need to add to IXP Manager which describe your IXP and are required for standard usage. Most of these actions can be found under the **IXP ADMIN ACTIONS** on the left hand side menu.

**Remember:** most of the forms for adding and editing the following entities have context help on each input field via the green *Help* button.

1. create your **infrastructures**. Generally, an infrastructure represents a collection of switches which form an IXP's peering LAN. The best way to think of an infrastructure is to think of it as *an IXP*.

    For example, INEX runs three infrastructures - INEX LAN1, INEX LAN2 and INEX Cork. Each of these consist of a unique set of switches and these infrastructures are not interconnected. They also have unique PeeringDB entries ([INEX LAN1](https://www.peeringdb.com/api/ix/48), [INEX LAN2](https://www.peeringdb.com/api/ix/387), [INEX Cork](https://www.peeringdb.com/api/ix/1262)) and IX-F entries ([INEX LAN1](https://db.ix-f.net/api/ixp/20), [INEX LAN2](https://db.ix-f.net/api/ixp/645), [INEX Cork](https://db.ix-f.net/api/ixp/646)) for each infrastructure.

    If you do not have a PeeringDB entry yet, then [register and create one](https://www.peeringdb.com/). Similarly, if you do not have an IX-F entry, email the IXPDB admins via `ixpdb-admin <at> euro-ix.net` with your IX's full name, short name, city / region / country, GPS coordinates and website URL.

2. Add your **facilities** (points of presence - the data centres where networks can connect to one of your IX switches).

3. Add your **racks**. You will need this later to add patch panels and switches for example.

4. You can now add switches. We have [good documentation for this here](https://docs.ixpmanager.org/usage/switches/). It is important to note that the **IXP Manager** server will need SNMP (v2) access to your switches and your switches should have a domain name registered in DNS. Avoid using IP addresses here.

    IXP Manager will query your switch via SNMP and discover its details as well as setting up all the switch ports in the database.

5. Add your VLAN(s). We would recommend two VLANs per infrastructure for peering purposes:

    * your production VLAN where your members will peer with each other.
    * a quarantine VLAN where you connect members initially for testing and also to move members to when your need to perform diagnostics away from the production LAN.

    When adding your production peering VLAN, you will want to check the *Include VLAN in the peering matrix (see help)* option and the *Include VLAN in the peering manager (see help)* option.

    Add *Network Information* for the peering LAN also. The *Network Information* is a submenu under the VLANs menu option.

6. Add your peering IP addresses. IXP Manager will let you add complete ranges (e.g. /24) and more sensible ranges of IPv6 (i.e. not an entire /64!).

7. Ensure [email is correctly configured](../usage/email.md).

8. **Now, a very important next step:** let us know you are using IXP Manager so we can add you [to the community map](https://www.ixpmanager.org/community/world-map). You can complete [the online form](https://www.ixpmanager.org/community/users/submit) or get [more details here](register.md).


The above constitutes the basic elements that are required to provision a customer.

For documentation on [adding and managing customers, see here](https://docs.ixpmanager.org/usage/customers/). And for details on [provisioning interfaces for your customers, see here](https://docs.ixpmanager.org/usage/interfaces/).


## Feature Checklist

The above section lists the essential set-up elements. Beyond those, IXP Manager has many features that require a little extra effort to set up as there is a manual element to many of them. What follows is a check list of these features:

* Graphing ([documentation](https://docs.ixpmanager.org/grapher/introduction/)) - at a minimum you will want to set up interface graphs via [mrtg](https://docs.ixpmanager.org/grapher/mrtg/). You should also look at peer to peer graphing via [sflow](https://docs.ixpmanager.org/grapher/sflow/) and latency graphing via [Smokeping](https://docs.ixpmanager.org/grapher/smokeping/).

* Routers - see [the generic documentation here](https://docs.ixpmanager.org/features/routers/). Then remember that no IX is complete without [route servers](https://docs.ixpmanager.org/features/route-servers/) with [IRRDB](https://docs.ixpmanager.org/features/irrdb/) and [RPKI](https://docs.ixpmanager.org/features/rpki/) filtering. We would highly recommend a [route collector](https://docs.ixpmanager.org/features/route-collectors/) on each infrastructure.

   * And while we're talking routers - consider an [AS112 service](https://docs.ixpmanager.org/features/as112/).

   * You should also set-up the [looking glass](https://docs.ixpmanager.org/features/looking-glass/) functionality on these servers. This is used to provide a looking glass to IX operators and members, for monitoring, for prefix filtering tools, etc.

* Make sure you have set up IXP Manager's [cron job](https://docs.ixpmanager.org/features/cronjobs/).

* Use the [cross connect / patch panel](https://docs.ixpmanager.org/features/patch-panels/) management features. As your IX grows and you end up with tens or hundreds of these you will profoundly regret it if you haven't used this feature from day one.

* Use IXP Manager [to automate your PTR ARPA records](https://docs.ixpmanager.org/features/dns-arpa/) for member assigned IP addresses on the peering LAN.

* Set-up your [IX-F export](https://docs.ixpmanager.org/features/ixf-export/) and let `ixpdb-admin (at) euro-ix (dot) net` know about it.

* If you are not statically configuring / using static l2acls for MAC addresses, then set up [MAC address discover](https://docs.ixpmanager.org/features/layer2-addresses/).

* Configure [Nagios monitoring](https://docs.ixpmanager.org/features/nagios/).

* Enable the member facing [*Peering Manager*](https://docs.ixpmanager.org/features/peering-manager/).

* Consider setting up BGP session discovery via sflow for the [peering matrix](https://docs.ixpmanager.org/features/peering-matrix/).

* Set up your [PeeringDB account in IXP Manager](https://docs.ixpmanager.org/features/peeringdb/) to enable all features including ease of adding customers.

* Allow IXP Manager to maintain your [RIR objects](https://docs.ixpmanager.org/features/rir-objects/) automatically.

* You may want to [skin some of the templates](https://docs.ixpmanager.org/features/skinning/). However, in the main, we would advise keeping this to a minimum or upgrades will become more complicated. Especially if you skin complex / core templates around functionality. There are some templates we do recommend you skin immediately:

   * the [support details page](https://github.com/inex/IXP-Manager/blob/master/resources/views/content/0/support.foil.php).

* Add any [static content](https://docs.ixpmanager.org/features/static-content/) you require.

* Automation - if you're so inclined to look at switch automation, see INEX's [templates here](https://github.com/inex/ixp-manager-provisioning) (Arista and Cumulus).


As you look through the above, do please note that we have given a lot of presentations over the years and many are linked [here with video](https://www.ixpmanager.org/presentations).


**Happy peering!**
