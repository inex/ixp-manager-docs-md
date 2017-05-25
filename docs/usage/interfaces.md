# Customer Interfaces

This section explains how to set up a customer interface.

## Database Overview

To fully understand how IXP Manager treats customer interfaces, you need a little background on the database schema. This will also help explain why we have laid out the UI as it is.

The original database schema dates from pre-2005 and has stood the test of time extremely well.

![Interface Schema](img/interfaces-schema.png)

The above is described as follows:

* Customers have a 1:n relationship with virtual interfaces (VI). A VI is a container object that represents a customer connection and all the elements that make up that connection.
* VIs have a 1:n relationship with physical interfaces (PI).
  * A physical interface in turn has a 1:1 relationship with switch ports (SP).
  * PIs represent what we say the customer has (e.g. a 1Gb port). The SP has information from the switch itself and can help identify inconsistencies with what was expected to be configured/billed and what has actually been provisioned).
  * PIs can also move between SPs (e.g. customer upgrades / switch replacements / etc.).
  * By schematically representing PIs and SPs as different entities, we can associate elements such as usage graphs to the PI so these remain consistent when a SP changes.
  * Adding a second (or more) PI to a VI indicates that the port is a LAG.
* VIs have a 1:n relationship with VLAN interfaces (VLI). You can consider the PI element the layer2 / phsyical element and the VLI element the layer3 element.
  * A VLI has a 1:1 mapping with a VLAN (typicaly the peering LAN).
  * If IPv4 is enabled, the VLI has a 1:1 mapping to an IPv4 address from the given VLAN.
  * If IPv6 is enabled, the VLI has a 1:1 mapping to an IPv6 address from the given VLAN.
  * The VLI also indicates if this interface should have a route server peering session, MD5 passwords, etc. (all explaing below).

## Provisioning an Interface via the Wizard

The best way to provision a new interface for a customer is to use the wizard. This can be accessed from the customer's overview page via a menu on the top right:

![Interface Wizard Menu](img/interfaces-menu-wizard.png)

When you open the wizard, you will see:

![Interface Wizard Menu](img/interfaces-wizard.png)

This can be used to provision a single port standard customer connection. If they customer needs a LAG or other non-standard options, these can be added afterwards.

### General Interface Settings

The customer should be prefilled and read-only as you enter the wizard from a specific customer overview page.

You would normally just select your main / primary peering VLAN from the `VLAN` dropdown. There are some notable exceptions:

* you may have more than one peering LAN. For example INEX runs two resilient peering networks in Dublin and a separate regional exchange called INEX Cork. These are all unique VLANs.
* if you are provisioning a port dedicated to a private VLAN, you would just select that VLAN but leave *IPv4 Enabled* and *IPv6 Enabled* unchecked as IP addressing on private VLANs in not within an IX's pervue.
* at INEX we also have quarantine VLANs for each peering VLAN. You would *typically* not select a quarantine VLAN here during provsioning unless you are using automation. Just put the interface in the primary peering LAN and let the *Physical Interface Settings* (see below) look after the quarantine flag.
* You should check the `Use 802.1q framing` checkbox if the port should be tagged facing the customer. If you are not using any automation tools, this will be informational for you rather than production affecting.
* Checking either or both of *IPv4 Enabled* and *IPv6 Enabled* will show the *IPv4 Details* and *IPv6 Details* (as per the above image) and enable these protocols for the customer's connection.
