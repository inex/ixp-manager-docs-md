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

To enable / disable these checks, edit the VLAN interface configuration and set IPvX Can Ping appropriately.

There is an additional option when editing a member's VLAN interface called *Busy Host*. This changes the Nagios ping fidelity from `250.0,20%!500.0,60%` to `1000.0,80%!2000.0,90%` which is useful for routers with slow / rate limited control planes.

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
    host_name               packet-clearing-house-dns-as42-ipv4-vlantag10-vliid109
    alias                   Packet Clearing House DNS / swi1-kcp1-1 / Peering VLAN #1.
    address                 185.6.36.60
    check_command           check-host-alive
    max_check_attempts      10
    notification_interval   120
    notification_period     24x7
    notification_options    d,u,r
    contact_groups          admins
}



### Service: 185.6.36.60 / inex.woodynet.net / Peering VLAN #1.

define service {
    use                     ixp-manager-member-service
    host_name               packet-clearing-house-dns-as42-ipv4-vlantag10-vliid109
    check_period            24x7
    max_check_attempts      3
    normal_check_interval   5
    retry_check_interval    1
    contact_groups          admins
    notification_interval   120
    notification_period     24x7
    notification_options    w,u,c,r
    service_description     PING
    check_command           check_ping!250.0,20%!500.0,60%
}
```

### Optional Parameters

You can optionally GET/POST any of the following to change elements of the default template. These are shown here as their interpretation in PHP with default values:

```php
// optional POST/GET parameters
'host_definition'               => $request->input( 'host_definition',        'ixp-manager-member-host'          ),
'host_check_command'            => $request->input( 'host_check_command',     'check-host-alive'                 ),
'max_check_attempts'            => $request->input( 'max_check_attempts',     '10'                               ),
'check_period'                  => $request->input( 'check_period',           '24x7'                             ),
'notification_interval'         => $request->input( 'notification_interval',  '120'                              ),
'notification_period'           => $request->input( 'notification_period',    '24x7'                             ),
'host_notification_options'     => $request->input( 'notification_options',   'd,u,r'                            ),
'check_interval'                => $request->input( 'check_interval',         '5'                                ),
'retry_check_interval'          => $request->input( 'retry_check_interval',   '1'                                ),
'service_definition'            => $request->input( 'service_definition',     'ixp-manager-member-service'       ),
'contact_groups'                => $request->input( 'contact_groups',         'admins'                           ),
'ping_check_command'            => $request->input( 'ping_check_command',     'check_ping!250.0,20%!500.0,60%'   ),
'pingbusy_check_command'        => $request->input( 'pingbusy_check_command', 'check_ping!1000.0,80%!2000.0,90%' ),
```

An example of changing two of these parameters is:

```sh
curl --data "host_definition=my-host-def&check_period=5x8" -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "X-IXP-Manager-API-Key: my-ixp-manager-api-key" \
    https://ixpexample.com/api/v4/nagios/customers/2/4
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
