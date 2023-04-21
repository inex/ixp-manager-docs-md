# Automated Provisioning

## Introduction

At INEX, we have been using IXP Manager for automated provisioning of our peering platform since 2017. We have [published all the provisioning templates we use in production here](https://github.com/inex/ixp-manager-provisioning). 

???+ info
    You are welcome to have a look at what's here and contribute feedback via the issues page or the ixpmanager mailing list. Having said that, provisioning is complicated and very specific to individual IXPs. Even if your IXP is running with the same two network operating systems that are in this repo, it is unlikely that people have the resources freely available to be able to make this work for you. 

This page has two sections:

1. An overview of INEX's own templates.
2. A description of the API endpoints that INEX uses which should allow the automated provisioning using any other system besides the one INEX uses.

## Overview on INEX's Templates

The templates INEX has published at the above link provide configuration support for Arista EOS and Cumulus Linux 3.4+/4.0+ devices using SaltStack.

The Arista EOS implementation uses NAPALM and can be easily modified for any other operating system which supports either NAPALM or netmiko.

The Cumulus Linux template implementation uses native SaltStack support, and treats the Cumulus Linux switch like any other Linux device. For an IXP, you need CL >= 3.4.2.

At the bare minimum, in order to make these work, you will need to be completely fluent with NAPALM and advanced use of SaltStack, including how to configure and maintain salt proxies. If you have multiple IXP configurations (e.g. live / test environments), you will also need to be fluent with the idea of multiple salt environments.

A good starting point would be [Mircea Ulinic's guides for integrating SaltStack and NAPALM](https://mirceaulinic.net/2017-02-14-network-automation-tutorial/). For a bigger-picture overview about how these templates hang together, we've done some presentations - see the [2017 and 2018 talks on automation on the IXP Manager website](https://www.ixpmanager.org/support/talks).

Note that there is no information in these presentations about the nitty gritty of getting all this stuff to work. The Apricot 2018 presentation involves lots of cheery handwaving and high level overview stuff, but very little detail other than some sample command-lines that we use.

In 2023/4 we hope to design a workshop / tutorial videos on this topic.

## API Endpoints

The API endpoints documented below should provide everything you need to provision all aspects of an IXP fabric. 

* The API endpoint URLs provided below are relative to your IXP Manager base URL (e.g. `https://ixp.example.com/`). 
* The `{switchname}` should be replaced with the name of your switch as entered in IXP Manager.
* We use `.yaml` in the examples but you should be able to replace this with `.json` also.

The INEX sample templates we reference below will get their dynamic information from two sources:

1. A static file of variables - see this SaltStack example: [variables.j2](https://github.com/inex/ixp-manager-provisioning/blob/master/saltstack/inex/pillar/variables.j2.dist); and
2. IXP Manager API endpoints as documented.
   

### Base Switch Configuration

* **Sample Arista template:** [configure_ixp_specific_base_config.j2](https://github.com/inex/ixp-manager-provisioning/blob/master/napalm/templates/arista-eos/configure_ixp_specific_base_config.j2.dist).
* **API endpoint:** `/api/v4/provisioner/switch/switch-name/{$switchname}.yaml`

**Sample output:**

```yaml
switch:
  name: swi1-exp1-1
  asn: 65000
  hostname: swi1-exp1-1.mgmt.example.com
  loopback_ip: 192.0.2.1
  loopback_name: Loopback0
  ipv4addr: 192.0.2.100
  model: DCS-7280SR-48C6
  active: true
  os: EOS
  id: 72
  macaddress: 11:22:33:44:55:66
  lastpolled: "2023-04-21T09:31:11+01:00"
  osversion: 4.25.4M
  snmpcommunity: supersecret
```

All of this data comes from the switch settings in IXP Manager. The `ipv4addr` is the management address.

As well as the base configuration shown the the template about, this information could also be used to provision:

* Initial BGP configuration for VXLAN;
* A DHCP server on your management network;
* Monitoring systems such as Nagios and LibreNMS.





### Layer3 Interfaces


* **Sample Arista template:** [configure_core_interfaces.j2](https://github.com/inex/ixp-manager-provisioning/blob/master/napalm/templates/arista-eos/configure_core_interfaces.j2).
* **API endpoint:** `/api/v4/provisioner/layer3interfaces/switch-name/{$switchname}.yaml`

**Sample output:**

```yaml
layer3interfaces:
- ipv4: 192.0.2.21/31
  description: 'LAN1: swi1-exp1-3 - swi1-exp1-1'
  bfd: true
  speed: 100000
  name: Ethernet51/1
  autoneg: true
  shutdown: false
- ipv4: 192.0.2.33/31
  description: 'LAN1: swi1-exp2-3 - swi1-exp1-1'
  bfd: true
  speed: 100000
  name: Ethernet53/1
  autoneg: true
  shutdown: false
- description: Loopback interface
  loopback: true
  ipv4: 192.0.2.1/32
  name: Loopback0
  shutdown: false
```

This API is used to set up the basic layer3 interface elements that are required in future stages to create a VXLAN overlay. The data comes from two sources on IXP Manager:

* Loopback interface - the switch settings.
* Interswitch links - the [core bundles](core-bundles.md) feature.






### VLANs


* **Sample Arista template:** [configure_vxlan.j2](https://github.com/inex/ixp-manager-provisioning/blob/master/napalm/templates/arista-eos/configure_vxlan.j2).
* **API endpoint:** `/api/v4/provisioner/vlans/switch-name/{$switchname}.yaml`

**Sample output:**

```yaml
vlans:
- name: IXP LAN1
  tag: 10
  private: false
  config_name: vl_peeringlan1
- name: Quarantine LAN1
  tag: 11
  private: false
  config_name: vl_quarantinelan1
- name: VoIP Peering LAN1
  tag: 12
  private: false
  config_name: VOIPPeeringLAN1
```

This information comes from the VLAN configuration on IXP Manager. The INEX sample template also configures VXLAN with this information.






### Layer2 Interfaces

???+ info
    Despite the template being called *cust* interfaces, this API endpoint is for both customer interfaces and layer2 core interfaces.


* **Sample Arista template:** [configure_cust_interfaces.j2](https://github.com/inex/ixp-manager-provisioning/blob/master/napalm/templates/arista-eos/configure_cust_interfaces.j2).
* **API endpoint:** `/api/v4/provisioner/layer2interfaces/switch-name/{$switchname}.yaml`

**Sample output:**

```yaml
layer2interfaces:
- type: edge
  description: Sample Member - No LAG
  dot1q: false
  virtualinterfaceid: 26
  lagframing: false
  vlans:
  - number: 10
    macaddresses:
    - 22:33:44:55:66:77
    ipaddresses:
      ipv4: 198.51.100.23
      ipv6: 2001:db8::23
  shutdown: false
  status: connected
  name: "1:3"
  speed: 10000
  autoneg: true
- type: edge
  description: Sample Member - LAG
  dot1q: false
  virtualinterfaceid: 251
  lagframing: true
  lagindex: 3
  vlans:
  - number: 10
    macaddresses:
    - 33:44:55:66:77:88
    ipaddresses:
      ipv4: 198.51.100.108
      ipv6: 2001:db8::108
  name: Port-Channel3
  lagmaster: true
  fastlacp: false
  lagmembers:
  - Ethernet5
  - Ethernet6
  shutdown: false
  status: connected
- type: edge
  description: Sample Member - LAG
  dot1q: false
  virtualinterfaceid: 251
  lagframing: true
  lagindex: 3
  vlans:
  - number: 10
    macaddresses:
    - 33:44:55:66:77:88
    ipaddresses:
      ipv4: 198.51.100.108
      ipv6: 2001:db8::108
  name: Ethernet5
  lagmaster: false
  fastlacp: false
  shutdown: false
  status: connected
  autoneg: true
  speed: 10000
  rate_limit: ~
- type: edge
  description: Sample Member - LAG
  dot1q: false
  virtualinterfaceid: 251
  lagframing: true
  lagindex: 3
  vlans:
  - number: 10
    macaddresses:
    - 33:44:55:66:77:88
    ipaddresses:
      ipv4: 198.51.100.108
      ipv6: 2001:db8::108
  name: Ethernet6
  lagmaster: false
  fastlacp: false
  shutdown: false
  status: connected
  autoneg: true
  speed: 10000
  rate_limit: ~
- type: core
  description: 'LAN1: swi1-exp2-3 to swi1-exp1-1 - Sample Core L2 Link'
  dot1q: true
  stp: false
  cost: ~
  preference: ~
  virtualinterfaceid: 439
  corebundleid: 30
  lagframing: true
  lagindex: 1000
  vlans:
  - number: 10
    macaddresses: []
  - number: 11
    macaddresses: []
  - number: 12
    macaddresses: []
  name: Port-Channel1000
  lagmaster: true
  fastlacp: true
  lagmembers:
  - "Ethernet48"
  shutdown: false
- type: core
  description: 'LAN1: swi1-exp2-3 to swi1-exp1-1 - Sample Core L2 Link'
  dot1q: true
  stp: false
  cost: ~
  preference: ~
  virtualinterfaceid: 439
  corebundleid: 30
  lagframing: true
  lagindex: 1000
  vlans:
  - number: 10
    macaddresses: []
  - number: 11
    macaddresses: []
  - number: 12
    macaddresses: []
  name: "Ethernet48"
  lagmaster: false
  fastlacp: true
  shutdown: false
  autoneg: true
  speed: 40000
```

The data comes from two sources on IXP Manager:

* Individual member interface configurations.
* Interswitch links - the [core bundles](core-bundles.md) feature.


### BGP




* **Sample Arista template:** [configure_bgp.j2](https://github.com/inex/ixp-manager-provisioning/blob/master/napalm/templates/arista-eos/configure_bgp.j2).
* **API endpoint:** `/api/v4/provisioner/routing/switch-name/{$switchname}.yaml`

**Sample output:**

```yaml
bgp:
  floodlist:
  - 192.0.2.2
  - 192.0.2.12
  - 192.0.2.10
  - 192.0.2.11
  - 192.0.2.40
  - 192.0.2.20
  - 192.0.2.0
  - 192.0.2.60
  - 192.0.2.22
  - 192.0.2.82
  - 192.0.2.23
  - 192.0.2.42
  - 192.0.2.15
  - 192.0.2.16
  - 192.0.2.17
  - 192.0.2.18
  adjacentasns:
    65082:
      description: swi1-exp1-3
      asn: 65082
      cost: 100
      preference: ~
    65002:
      description: swi1-exp2-3
      asn: 65002
      cost: 850
      preference: ~
  routerid: 192.0.2.1
  local_as: 65000
  out:
    pg-ebgp-ipv4-ixp:
      neighbors:
        192.0.2.120:
          description: swi1-exp1-3
          remote_as: 65082
          cost: 100
          preference: ~
        192.0.2.132:
          description: swi1-exp2-3
          remote_as: 65002
          cost: 850
          preference: ~
```

This completes the layer2 underlay for VXLAN. The sources of information for this are the switches and core bundles in IXP Manager.
