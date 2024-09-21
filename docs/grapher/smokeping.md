# Backend: Smokeping

Latency graphs are a tool for monitoring latency / packet loss to the routers of IXP partipants and they can be an invaluable asset when diagnosing many IXP issues.

**While they should never be used as a tool for monitoring IXP latency or packet loss** (as routers de-prioritise ICMP requests and/or may not have a suitably powerful management plane), they can act as an extremely useful tool for identifying and diagnosing customer / member issues. **What we really look for here is recent changes over time.**

**IXP Manager** can configure Smokeping to monitor member routers and display those graphs in member statistic pages. Presuming it is installed.



## Target Selection

This section explains the rules on how a member router (target) is selected to be included in the generated Smokeping configuration.

When generating a list of targets per VLAN and protocol, the API call to IXP Manager will select all VLAN interfaces (member routers) where:

* that protocol (IPv4/6) is enabled for the member;
* *Can Ping* has been checked for that protocol; and
* the virtual interface pertaining to the VLAN interface has at least on physical interface in the connected state.


## Generating Smokeping Targets

You can use the **IXP Manager** API to get the Smokeping target configurations for a given VLAN and protocol using the following endpoint format (both GET and POST requests work):

```
https://ixp.example.com/api/v4/grapher/config?backend=smokeping&vlanid=10&protocol=ipv4
```

In the above, the parameters are:

* `vlanid` is the database ID (*DB ID*) of the VLAN. You can find the DB ID in IXP Manager in the VLAN table (select *VLANs* from the left hand side menu).
* `protocol` is either `ipv4` or `ipv6`.

If either of these are invalid, the API will return with a HTTP 404 response.

And example of a Smokeping target in the response is:

```
# AS112 Reverse DNS / 185.6.36.6
+++ vlanint_86_ipv4
menu = AS112 Reverse DNS (IPv4)
title =  Peering VLAN #1 :: AS112 Reverse DNS via 185.6.36.6
probe = FPing
host = 185.6.36.6
```

### Optional Parameters

You can optionally POST any of the above parameters and none, one or both of the following to change elements of the default template:

* `level`: the Smokeping level / hierarchy of the target. Defaults to `+++`.
* `probe`: the probe to use when measuring latency to the target. Defaults for `FPing` for IPv4 and `FPing6` for IPv6.

An example of changing these parameters is:

```sh
curl --data "backend=smokeping&protocol=ipv4&vlanid=10&level=%2B%2B&probe=MyPing" -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "X-IXP-Manager-API-Key: my-ixp-manager-api-key" \
    https://ixpexample.com/api/v4/grapher/config
```


### Templates / Skinning

You can use [skinning](../features/skinning.md) to make changes to the bundled `default` template or, **preferably**, add your own.

Let's say you wanted to add your own template called `mytemplate1` and your skin is named `myskin`. The best way to proceed is to copy the bundled example:

```sh
cd $IXPROOT
mkdir -p resources/skins/myskin/services/grapher/smokeping
cp resources/views/services/grapher/smokeping/default.foil.php \
    resources/skins/myskin/services/grapher/smokeping/mytemplate1.foil.php
```

You can now edit this template as required. The only constraint on the template name is it can only contain characters from the classes `a-z, 0-9, -`. **NB:** do not use uppercase characters.

The following variables are available in the template:

* `$t->vlis`: array of the VLAN interfaces/targets - it is generated [by the Repositories\VlanInterface::getForProto() function](https://github.com/inex/IXP-Manager/blob/master/database/Repositories/VlanInterface.php#L18).
* `$t->vlan`: instance of the [`Vlan` entity object](https://github.com/inex/IXP-Manager/blob/master/database/Entities/Vlan.php).
* `$t->protocol`: either `4` or `6`.
* `$t->probe` and `$t->level` as defined above / passed via a post request.



## Setting Up Smokeping

This section explains how to set up Smokeping with IXP Manager. We assume you already have a base install of Smokeping.

### Generating / Updating Targets

At INEX, we would use a script [such as this one which is bundled with IXP Manager](https://github.com/inex/IXP-Manager/tree/master/tools/runtime/smokeping) to (re)generate our targets by cron and update Smokeping if necessary.

To use this script yourself, you just need to copy it to the appropriate Smokeping server and edit the first few lines:

```bash
KEY="my-ixp-manager-api-key"
URL="https://ixp.example.com/api/v4/grapher/config?backend=smokeping"
ETCPATH="/etc/smokeping"
SMOKEPING="/usr/bin/smokeping"
SMOKEPING_RELOAD="/etc/rc.d/smokeping reload"
VLANS="1 2"
PROTOCOLS="ipv4 ipv6"
```

where:

 * `KEY` is your IXP Manager [API key](../features/api.md).
 * `URL` is the API endpoint as described above.
 * `ETCPATH` is where the script puts the target files (named `$ETCPATH/targets-vlan${vlanid}-${proto}.cfg`)
 * `SMOKEPING` is the Smokeping binary command. Just used to validate the config with `--check` before reloading.
 * `SMOKEPING_RELOAD` - the command to reload Smokeping.
 * `VLANS` - space separated list of VLAN DB IDs as described above. You probably only have one of these typically.
 * `PROTOCOLS` - the protocols to generate the configuration for.

The script iterates over the VLAN IDs and protocols to create the individual configuration files.

### Using Targets in Smokeping

Once the above target file(s) are created, we can use them in our standard Smokeping configuration file as follows:

```
+ infra_1
menu = IXP Infrastructure 1
title = IXP Infrastructure 1


++ vlan_1
menu = Peering VLAN 1
title = IXP Infra 1 :: Peering VLAN 1


@include targets-vlan1-ipv4.cfg
@include targets-vlan1-ipv6.cfg
```

## Apache Configuration

You need to be able to configure IXP Manager with the base Smokeping URL such as `http://www.example.com/smokeping`. This should be the URL to the standard entry page to Smokeping.

IXP Manager will add the trailing slash and assume the directory index is configured for the CGI script. Thus you need an Apache configuration such as:

```
ScriptAlias /smokeping/smokeping.cgi /usr/lib/cgi-bin/smokeping.cgi
Alias /smokeping /usr/share/smokeping/www

<Directory "/usr/share/smokeping/www">
    Options FollowSymLinks
    DirectoryIndex smokeping.cgi
</Directory>
```


## IXP Manager Configuration

Once you have configured Smokeping and Apache/web server as above, you really just need to set the following in your IXP Manager `.env` file:

```
# Add smokeping to the grapher backends:
GRAPHER_BACKENDS="...|smokeping|..."

# Mark it as enabled (this just affects whether certain UI elements are shown):
GRAPHER_BACKEND_SMOKEPING_ENABLED=true

# And set the default location to fetch the Smokeping graphs from:
GRAPHER_BACKEND_SMOKEPING_URL="http://www.example.com/smokeping"
```

where the URL is as you set up in Apache above.

There may be instances where you have multiple VLANs where it is not possible to have a single Smokeping instance graph latency for all of them. Particularly as the Smokeping daemon for a given VLAN needs to have an interface / IP address on that VLAN.

INEX has such a situation where we have a regional exchange, *INEX Cork*, that is located in a different city to the main INEX LANs and IXP Manager. In this situation, you can configure Smokeping URL overrides on a per VLAN basis by creating a file called `$IXPROOT/config/grapher_smokeping_overrides.php` which returns an array as follows:

```php
<?php

return [

    'per_vlan_urls' => [
        2 => 'http://www.example.com/smokeping',
        4 => 'http://www.example2.com/smokeping',
    ],

];
```

where the array index (`2` and `4` in the above example) is the VLAN DB ID as explained above.

Any VLANs without a specific override configured in this way will fall back to the `GRAPHER_BACKEND_SMOKEPING_URL` setting.


## Viewing Smokeping in IXP Manager

When configured correctly, there will be a latency button available (clock icon) in the member graphs in both the member and admin sections.


## Troubleshooting

See [issue #122](https://github.com/inex/IXP-Manager/issues/122) for a discussion on Ubuntu installation and diagnosing issues in general (relates to IXP Manager v3 but may still be useful).


IXP Manager will call something like the following to fetch graphs from Smokeping:

```php
file_get_contents( 'https://www.example.com/smokeping/?.....' )
```

You should see these requests to Smokeping in your Smokeping web server log files. Find these and compare them to the URLs that Smokeping itself generates for its own display of the images to ensure you have everything - and especially the Smokeping URL in IXP configuration set up correctly.

Also, try testing these URLs directly on the IXP Manager server via:

```php
php -r 'echo file_get_contents( "https://..." );'
```
