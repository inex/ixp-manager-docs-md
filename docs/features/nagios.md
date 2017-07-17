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

To enable / disable these checks, edit the VLAN interface configuration and set IPvX Can Ping appropriately. *Note that when IPvX Can Ping is disabled, the host definition is created anyway as this would be used for other Nagios checks such as route collector sessions.*

There is an additional option when editing a member's VLAN interface called *Busy Host*. This changes the Nagios ping fidelity from `250.0,20%!500.0,60%` to `1000.0,80%!2000.0,90%` (using the default object definitions which are configurable). This is useful for routers with slow / rate limited control planes.

Members are added to a number of hostgroups also:

* a per-switch hostgroup;
* a per cabinet hostgroup;
* a per location / data centre hostgroup;
* an all members hostgroup.

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

You will notice that the above configuration example is very light and is missing an awful lot of Nagios required configuration directives. This is intentional so that IXP Manager is not too prescriptive and allows you to define your own Nagios objects without having to resort to skinning IXP Manager.

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


## Switch Monitoring

We monitor all production peering LAN switches for a number of difference services (see below).

IXP Manager produces a host configuration for each production switch such as:

```
#
# swi2-dc1-1 - DUB01.XX.YY.ZZ, Data Centre DUB1.
#

define host {
    use                     ixp-manager-production-switch
    host_name               swi2-dc1-1.mgmt.inex.ie
    alias                   swi2-dc1-1
    address                 192.0.2.4
}
```

Members are added to a number of hostgroups also:

* switches per location / data centre;
* all switches in the requested infrastructure;
* grouped by vendor name (the vendor's *shortname* as defined in IXP Manager);
* grouped by vendor model (as discovered by SNMP).

These hostgroups are very useful when defining service checks.

You can use the **IXP Manager** API to get the Nagios configuration for a given infrastructure using the following endpoint format (both GET and POST requests work):

```
https://ixp.example.com/api/v4/nagios/switches/{infraid}
```

where:

* `infraid` is the database ID (*DB ID*) of the infrastructure. You can find the DB ID in IXP Manager in the infrastructures table (select *Infrastructures* from the left hand side menu).

You can use [skinning](skinning.md) to make changes to the bundled `default` template or, **preferably**, add your own.

Let's say you wanted to add your own template called `myswtemplate1` and your skin is named `myskin`. The best way to proceed is to copy the bundled example:

```sh
cd $IXPROOT
mkdir -p resources/skins/myskin/api/v4/nagios/switches
cp resources/views/api/v4/nagios/switches/default.foil.php resources/skins/myskin/api/v4/nagios/switches/myswtemplate1.foil.php
```

You can then elect to use this template by tacking the name onto the API request:

```
https://ixp.example.com/api/v4/nagios/switches/{infraid}/{template}
```

where, in this example, `{template}` would be: `myswtemplate1`.

You can pass one optional parameter to Nagios via GET/POST which is the host definition to inherit from (see customer reachability testing about for full details and examples):

```sh
curl --data "host_definition=my-sw-host-def" -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "X-IXP-Manager-API-Key: my-ixp-manager-api-key" \
    https://ixpexample.com/api/v4/nagios/switches/2
```

### Service Checking

The recommended way to check various services on your production switches is to use the host groups created by the above switch API call. An example of the hostgroups produced include:

1. `ixp-production-switches-infraid-2`: all switches on an infrastructure with DB ID 2;
2. `ixp-switches-infraid-2-dc-dub1`: all switches in location dc-dub1;
2. `ixp-switches-infraid-2-extreme`: all Extreme switches on an infrastructure with DB ID 2; and
3. `ixp-switches-infraid-2-extreme-x670g2-48x-4q`: all Extreme switches of model X670G2-48x-4q on an infrastructure with DB ID 2.

Using these, you can create generic service definitions to apply to all hosts such as:

```
define service{
    use                             my-ixp-production-switch-service
    hostgroup_name                  ixp-production-switches-infraid-1, ixp-production-switches-infraid-2
    service_description             ping - IPv4
    check_command                   check_ping_ipv4!10!100.0,10%!200.0,20%
}

define service  {
    use                             my-ixp-production-switch-service
    hostgroup_name                  ixp-production-switches-infraid-1, ixp-production-switches-infraid-2
    service_description             SSH
    check_command                   check_ssh
}
```

You can target vendor / model specific checks as appropriate:

```
define service{
    use                             my-ixp-production-switch-service
    hostgroup_name                  ixp-switches-infraid-1-extreme, ixp-switches-infraid-2-extreme
    service_description             Chassis
    check_command                   check_extreme_chassis
}
```

The one thing you'll need to keep an eye on is adding hostgroups to service checks as you create new infrastructures / add new switch vendors / models.

**Hint:** over the years, we at [INEX](https://www.inex.ie/) have written a number of switch chassis check scripts and these can be found on Github at [barryo/nagios-plugins](https://github.com/barryo/nagios-plugins).

For example the Extreme version checks and returns something like:

> OK - CPU: 5sec - 10%. Uptime: 62.8 days. PSUs: 1 - presentOK: 2 - presentOK:. Overall system power state: redundant power available. Fans: [101 - OK (4311 RPM)]: [102 - OK (9273 RPM)]: [103 - OK (4468 RPM)]: [104 - OK (9637 RPM)]: [105 - OK (4165 RPM)]: [106 - OK (9273 RPM)]:. Temp: 34'C. Memory (slot:usage%): 1:29%.


## Birdseye Daemon Monitoring

We monitor our Bird instances at INEX directly through Birdseye, the software we use for our [looking glass](looking-glass.md). This means it is currently tightly coupled to Bird and Birdseye until such time as we look at a second router software.

IXP Manager produces a host and service configuration for each router such as:

```
define host     {
        use                     ixp-manager-host-birdseye-daemon
        host_name               bird-rc1q-cork-ipv4
        alias                   INEX Cork - Quarantine Route Collector - IPv4
        address                 10.40.5.134
        _apiurl                 http://rc1q-ipv4.cork.inex.ie/api
}

define service     {
    use                     ixp-manager-service-birdseye-daemon
    host_name               bird-rc1q-cork-ipv4
}
```

You can use the **IXP Manager** API to get the Nagios configuration for all or a given VLAN using the following endpoint format (both GET and POST requests work):

```
https://ixp.example.com/api/v4/nagios/birdseye-daemons
https://ixp.example.com/api/v4/nagios/birdseye-daemons/{template}
https://ixp.example.com/api/v4/nagios/birdseye-daemons/default/{vlanid}
https://ixp.example.com/api/v4/nagios/birdseye-daemons/{template}/{vlanid}
```

where:

* `{template}` is the optional skin (see below).
* `{vlanid}` is the VLAN id to limit the results to. If setting this, you need to provide a template also (or `default` for the standard template).


You can use [skinning](skinning.md) to make changes to the bundled `default` template or, **preferably**, add your own.

Let's say you wanted to add your own template called `mybetemplate1` and your skin is named `myskin`. The best way to proceed is to copy the bundled example:

```sh
cd $IXPROOT
mkdir -p resources/skins/myskin/api/v4/nagios/birdseye-daemons
cp resources/views/api/v4/nagios/birdseye-daemons/default.foil.php resources/skins/myskin/api/v4/nagios/birdseye-daemons/mybetemplate1.foil.php
```

You can then elect to use this template by tacking the name onto the API request:

```
https://ixp.example.com/api/v4/nagios/birdseye-daemons/{template}
```

where, in this example, `{template}` would be: `mybetemplate1`.

You can pass two optional parameter to Nagios via GET/POST which is the host and service definition to inherit from (see customer reachability testing about for full details and examples):

```sh
curl --data "host_definition=my-be-host-def&service_definition=my-be-srv-def" -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "X-IXP-Manager-API-Key: my-ixp-manager-api-key" \
    https://ixpexample.com/api/v4/nagios/birdseye-daemons
```

The default values for the host and service definitions are `ixp-manager-host-birdseye-daemon` and `ixp-manager-service-birdseye-daemon` respectively.


### Service Checking

You will need to create a parent host and service definition for the generated configuration such as:

```
define host {
    name                    ixp-manager-host-birdseye-daemon
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
    name                    ixp-manager-service-birdseye-daemon
    service_description     Bird BGP Service
    check_command           check_birdseye_daemon!$_HOSTAPIURL$
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

define command{
        command_name    check_birdseye_daemon
        command_line    /usr/local/nagios-plugins-other/nagios-check-birdseye.php -a $ARG1$
}
```

The Nagios script we use is bundled with [inex/birdseye](https://github.com/inex/birdseye) and can be found [here](https://github.com/inex/birdseye/tree/master/bin).

Typical Nagios state output:

> OK: Bird 1.6.2. Bird's Eye 1.0.4. Router ID 192.0.2.126. Uptime: 235 days. Last Reconfigure: 2017-07-17 16:00:04.26 BGP sessions up of 28.
