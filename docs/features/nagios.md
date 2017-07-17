# Nagios Monitoring

At [INEX](https://www.inex.ie/) we use Nagios to monitor a number of production services including:

* peering LAN switches;
* member reachability (ping v4/v6);
* member route collector sessions;
* member route server sessions.

IXP Manager can generate configuration to monitor the above for you.

**NB: IXP Manager will not install and configure Nagios from scratch. You need a working Nagios installation first and then IXP Manager will automate the above areas of the configuration.**

## Historical Notes

If you have used Nagios on IXP Manager <4.5, then how the configuration is generated has changed. The [older documentation may be available here](https://github.com/inex/IXP-Manager/wiki/Nagios). In previous versions of IXP Manager, we generated entire / monolithic Nagios configuration files. We have found in practice that this does not scale well and creates a number of limitations.

IXP Manager >= v4.5 now simply creates the targets on a per VLAN and protocol basis.

## Monitoring Member Reachability

We monitor all member router interfaces (unless asked not to) via ICMP[v6] pings with Nagios. This is all controlled by the Nagios configuration created with this feature.

To enable / disable these checks, edit the VLAN interface configuration and set IPvX Can Ping appropriately. *Note that when canping is disabled, the host definition is created anyway as this would be used for other Nagios checks such as route collector sessions.*

There is an additional option when editing a member's VLAN interface called *Busy Host*. This changes the Nagios ping fidelity from `250.0,20%!500.0,60%` to `1000.0,80%!2000.0,90%` (using the default object definitions which are configurable). This is useful for routers with slow / rate limited control planes.

Members are added to a number of hostgroups also:

* a per-switch hostgroup;
* a per cabinet hostgroup;
* a per location / data centre hostgroup;
* a all members hostgroup.

These hostgroups are very useful to single out issues and for post-maintenance checks.

You can use the **IXP Manager** API to get the Nagios configuration for a given VLAN and protocol using the following endpoint format (both GET and POST requests work):

```
https://ixp.example.com/api/v4/nagios/customers/{vlanid}/{protocol}
```

where:

* `vlanid` is the database ID (*DB ID*) of the VLAN. You can find the DB ID in IXP Manager in the VLAN table (select *VLANs* from the left hand side menu).
* `protocol` is either `4` for `IPv4` or 6 for `IPv6`.

If either of these are invalid, the API will return with a HTTP 404 response.

And example of a target in the reponse is:

```
###############################################################################################
###
### Packet Clearing House DNS
###
### Equinix DB2 (Kilcarbery) / Packet Clearing House DNS / swi1-kcp1-1.
###

### Host: 185.6.36.60 / inex.woodynet.net / Peering VLAN #1.

define host {
    use                     ixp-manager-member-host
    host_name               packet-clearing-house-dns-as42-ipv4-vlanid2-vliid109
    alias                   Packet Clearing House DNS / swi1-kcp1-1 / Peering VLAN #1.
    address                 185.6.36.60
}

### Service: 185.6.36.60 / inex.woodynet.net / Peering VLAN #1.

define service {
    use                     ixp-manager-member-ping-service
    host_name               packet-clearing-house-dns-as42-ipv4-vlanid2-vliid109
}
```

### Configuring Nagios for Member Reachability

You will notice that the above configuration example is very light and is missing an awful lot of required Nagios required configuration directives. This is intentional so that IXP Manager is not too prescriptive and allows you to define your own Nagios objects without having to resort to skinning IXP Manager.

Two of the most important elements of Nagios configuration which you need to understand are [object definitions](https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/objectdefinitions.html) and [object inheritance](https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/objectinheritance.html).

You can pass three optional parameters to Nagios via GET/POST and these are:

1. `host_definition`; defaults to: `ixp-manager-member-host`.
2. `service_definition`; defaults to `ixp-manager-member-service`.
3. `ping_service_definition`; defaults to: `ixp-manager-member-ping-service`.

An example of changing two of these parameters is:

```sh
curl --data "host_definition=my-host-def&service_definition=my-service-def" -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "X-IXP-Manager-API-Key: my-ixp-manager-api-key" \
    https://ixpexample.com/api/v4/nagios/customers/2/4
```

An example of the three objects that INEX use for this are:

```
define host {
    name                    ixp-manager-member-host
    check_command           check-host-alive
    check_period            24x7
    max_check_attempts      10
    notification_interval   120
    notification_period     24x7
    notification_options    d,u,r
    contact_groups          admins
    register                0
}

define service {
    name                    ixp-manager-member-service
    check_period            24x7
    max_check_attempts      10
    check_interval          5
    retry_check_interval    1
    contact_groups          admins
    notification_interval   120
    notification_period     24x7
    notification_options    w,u,c,r
    register                0
}

define service {
    name                    ixp-manager-member-ping-service
    use                     ixp-manager-member-service
    service_description     PING
    check_command           check_ping!250.0,20%!500.0,60%
    register                0
}
```

### Templates / Skinning

You can use [skinning](skinning.md) to make changes to the bundled `default` template or, **preferably**, add your own.

Let's say you wanted to add your own template called `mytemplate1` and your skin is named `myskin`. The best way to proceed is to copy the bundled example:

```sh
cd $IXPROOT
mkdir -p resources/skins/myskin/api/v4/nagios/customers
cp resources/views/api/v4/nagios/customers/default.foil.php resources/skins/myskin/api/v4/nagios/customers/mytemplate1.foil.php
```

You can now edit this template as required. The only constraint on the template name is it can only contain characters from the classes `a-z, 0-9, -`. **NB:** do not use uppercase characters.

You can then elect to use this template by tacking the name onto the API request:

```
https://ixp.example.com/api/v4/nagios/customers/{vlanid}/{protocol}/{template}
```

where, in this example, `{template}` would be: `mytemplate1`.

*As a policy, INEX tends to use the bundled templates and as such they should be fit for general purpose.*
