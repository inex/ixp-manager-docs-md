# Smokeping

Smokeping is a tool for monitoring network latency and is an invaluable asset when diagnosing many IXP issues.

> While it should never be used as a tool for monitoring IXP latency (as routers de-prioritise ICMP requests and handle them in their management plane, it acts more of a indication of the router load than the latency of the exchange fabric), it can be an extremely useful tool for identifying and diagnosing other customer / member issues.

IXP Manager can configure Smokeping to monitor member routers and display those graphs in member statistic pages. Presuming it is installed.

## Historical Notes

If you have used Smokeping on IXP Manager <4.5, then how the configuration is generated has changed. The [older documentation may be available here](https://github.com/inex/IXP-Manager/wiki/Smokeping). In previous versions of IXP Manager, we generated entire / monolithic Smokeping configuration files. We have found in practice that this does not scale well and creates a number of limitations.

IXP Manager >= v4.5 now simply creates the targets on a per VLAN and protocol basis.

## Target Selection

This section explains the rules on how a member router (target) is selected to be included in the generated Smokeping configuration.

When generating a list of targets per VLAN and protocol, the API call to IXP Manager will select all VLAN interfaces (member routers) where:

* that protocol (IPv4/6) is enabled for the member;
* *Can Ping* has been checked for that protocol; and
* the virtual interface pertaining to the VLAN interface has at least on physical interface in the connected state.

## Generating Smokeping Targets

You can use the **IXP Manager** API to get the Smokeping target configurations for a given VLAN and protocol using the following endpoint format (both GET and POST requests work):

```
https://ixp.example.com/api/v4/vlan/smokeping/{vlanid}/{protocol}
```

where:

* `vlanid` is the database ID (*DB ID*) of the VLAN. You can find the DB ID in IXP Manager in the VLAN table (select *VLANs* from the left hand side menu).
* `protocol` is either `4` for `IPv4` or 6 for `IPv6`.

If either of these are invalid, the API will return with a HTTP 404 response.

And example of a target in the reponse is:

```
# AS112 Reverse DNS / 185.6.36.6
+++ vlanint_86_ipv4
menu = AS112 Reverse DNS (IPv4)
title =  Peering VLAN #1 :: AS112 Reverse DNS via 185.6.36.6
probe = FPing
host = 185.6.36.6
```

### Optional Parameters

You can optionally POST one or both of the following to change elements of the default template:

* `level`: the Smokeping level / hierarchy of the target. Defaults to `+++`.
* `probe`: the probe to use when measuring latency to the target. Defaults for `FPing` for IPv4 and `FPing6` for IPv6.

An example of changing these parameters is:

```sh
curl --data "level=%2B%2B&probe=MyPing" -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "X-IXP-Manager-API-Key: my-ixp-manager-api-key" \
    https://ixpexample.com/api/v4/vlan/smokeping/2/4
```


### Templates / Skinning

You can use [skinning](skinning.md) to make changes to the bundled `default` template or, **preferably**, add your own.

Let's say you wanted to add your own template called `mytemplate1` and your skin is named `myskin`. The best way to proceed is to copy the bundled example:

```sh
cd $IXPROOT
mkdir -p resources/skins/myskin/api/v4/vlan/smokeping
cp resources/views/api/v4/vlan/smokeping/default.foil.php resources/skins/myskin/api/v4/vlan/smokeping/mytemplate1.foil.php
```

You can now edit this template as required. The only constraint on the template name is it can only contain characters from the classes `a-z, 0-9, -`. **NB:** do not use uppercase characters.

The following variables are available in the template:

* `$t->vlis`: array of the VLAN interfaces/targets - it is generated [by the Repositories\VlanInterface::getForProto() function](https://github.com/inex/IXP-Manager/blob/master/database/Repositories/VlanInterface.php#L18).
* `$t->vlan`: instance of the [`Vlan` entity object](https://github.com/inex/IXP-Manager/blob/master/database/Entities/Vlan.php).
* `$t->protocol`: either `4` or `6`.
* `probe` and `level` as defined above / passed via a post request.



## Setting Up Smokeping

This section explains how to set up Smokeping with IXP Manager. We assume you already have a base install of Smokeping.

### Generating / Updating Targets

At INEX, we would use a script such as the following to (re)generate our targets by cron and update Smokeping if necessary.




When scripting, we would normally pull the JSON object using something like:

```bash
#! /usr/bin/env bash

KEY="your-ixp-manager-api-key"
URL="https://ixp.example.com/api/v4/dns/arpa"
VLANIDS="1 2"
PROTOCOLS="4 6"

for v in $VLANIDS; do
    for p in $PROTOCOLS; do

        cmd="/usr/local/bin/curl --fail -s             \
            -H \"X-IXP-Manager-API-Key: ${KEY}\"       \
            ${URL}/${v}/${p}                           \
                >/tmp/dns-arpa-vlanid$v-ipv$p.json.$$"
        eval $cmd

        if [[ $? -ne 0 ]]; then
            echo "ERROR: non-zero return from DNS ARPA API call for vlan ID $v with protocol $p"
            continue
        fi

        // do something

        rm /tmp/dns-arpa-vlanid$v-ipv$p.json.$$
    done
done
```




### Sample Script

At INEX, we have (for example) one peering LAN that is a /25 IPv4 network and so is not a zone file in its own right. As such, we make up the zone file using includes. The main zone file looks like:

```
$TTL 86400

$INCLUDE /usr/local/etc/namedb/zones/soa-0.2.192.in-addr.arpa.inc

$INCLUDE zones/inex-dns-slave-nslist.inc

$INCLUDE zones/reverse-mgmt-hosts-ipv4.include
$INCLUDE zones/reverse-vlan-12-ipv4.include
```

The SOA file looks like (as you might expect):

```
@               IN      SOA     ns.example.come.     hostmaster.example.com. (
                        2017051701      ; Serial
                        43200           ; Refresh
                        7200            ; Retry
                        1209600         ; Expire
                        7200 )          ; Minimum
```

The `reverse-vlan-12-ipv4.include` is the output of the ISC Bind `bind` template above for a given VLAN ID.

We use the sample script `update-dns-from-ixp-manager.sh` which can be found [in this directory](https://github.com/inex/IXP-Manager/blob/master/tools/runtime/dns-arpa) to keep this updated ourselves.

IXP Manager Configuration

Add the following to your application.ini and alter as appropriate:

;; destination file for the configuration. If not set, the generator sends it to stdout
;smokeping.conf.dstfile = '/etc/smokeping/config'

;; Complete URL path of the SmokePing.cgi (mandatory)
smokeping.conf.cgiurl = "https://www.example.com/smokeping/smokeping.cgi"

;; A directory which is visible on your webserver where SmokePing can cache graphs. (mandatory)
smokeping.conf.imgcache = "/usr/local/smokeping/htdocs/img"

;; Either an absolute URL to the imgcache directory or one relative to the directory where you keep the SmokePing cgi. (mandatory)
smokeping.conf.imgurl = "/smokeping/img"

;; The directory where SmokePing can keep its rrd files. (mandatory)
smokeping.conf.datadir = "/usr/local/var/smokeping"

;; The directory where SmokePing keeps its pid when daemonised. (mandatory)
smokeping.conf.piddir = "/usr/local/var/smokeping"

;; Path to the mail template for DYNAMIC hosts. This mail template must contain keywords of the
;; form <##keyword##>. There is a sample template included with SmokePing. (mandatory)
smokeping.conf.smokemail = "/usr/local/etc/smokeping/smokemail"

;; Smokeping typically includes a file with paths to various executables
;; Set the full path and filename for that include here if you wish
smokeping.conf.pathnames = "/etc/smokeping/config.d/pathnames"

;; The above cover all the mandatory settings. You can add other options as follows and
;; they will be included in the general section of the Smokeping config.

smokeping.oconf.tmail = "/usr/local/etc/smokeping/tmail"
smokeping.oconf.syslogfacility = "local0"
Then, edit your IXP(s) (either from the IXPs menu item for multi-IXP mode or via the Infrastructures menu item for single IXP mode); and set the Smokeping URL to the htdocs directory of your Smokeping installaltion - e.g. http://127.0.0.1/smokeping. This should be accessible without username / password to the server running IXP Manager.

Smokeping Configuration

See the template files here which use some of the variables you set in application.ini above. If you want to change these, please do so via the skinning mechanism.

You can then generate the configuration via:

APPLICATION_PATH/bin/ixptool.php -a smokeping-cli.gen-conf >/path/to/smokeping/config
If you set smokeping.conf.dstfile above, then you can just do:

APPLICATION_PATH/bin/ixptool.php -a smokeping-cli.gen-conf
and allow cron to email any potential error output. After this, just (re)start Smokeping.

A number of parameters can be specified on the command line via comma separated pairs such as -p param1=value1,param2=vlaue2. These parameters are:

ixp - the id of the IXP to generate the configuration for - mandatory in multi-IXP environments.
cgiurl, imgcache, imgurl, datadir, piddir and smokemail these can be specific on the command line rather than the application.ini file which is useful for multi-IXP environments.
Needless to say, Smokeping needs to run on a host that has access to your peering VLAN(s) and it will only monitor interfaces with an IPv4/6 address that has the appropriate Can Ping flag set in the VLAN interface.

Apache Configuration

You need to be able to pass IXP Manager a Smokeping URL such as http://127.0.0.1/smokeping. IXP Manager will add the trailing slash as assume the directory index is configured for the CGI script. Thus you need an Apache configuration such as:

ScriptAlias /smokeping/smokeping.cgi /usr/lib/cgi-bin/smokeping.cgi
Alias /smokeping /usr/share/smokeping/www

<Directory "/usr/share/smokeping/www">
    Options FollowSymLinks
    DirectoryIndex smokeping.cgi
</Directory>
Viewing Smokeping in IXP Manager

There will be a Smokeping button available in the member drilldown graphs (per port graphs) in both the member and admin sections.

Future Expansion?

Allow customers to specify ping beacon(s) in their network (such as DNS servers) that we would monitor on their behalf to help provide a truer indication of latency.

Troubleshooting

See issue #122 for a discussion on Ubuntu installation and diagnosing issues in general.

When you look at the source HTML of the Smokeping page that IXP Manager generates, you'll see generated Smokeping image URLs like the following:

https://www.example.com/ixp/smokeping/retrieve-image/ixp/1/scale/3hours/infra/2/vlan/3/vlanint/94/proto/ipv4
IXP Manager will call something like

file_get_contents( 'https://www.example.com/smokeping/?.....' )
You should see these requests to Smokeping in your Smokeping web server log files. Find these and compare them to the URLs that Smokeping itself generates for its own display of the images to ensure you have everything - and especially the Smokeping URL in IXP configuration set up correctly.

Also, try testing these URLs directly on the IXP Manager server via:

php -r 'echo file_get_contents( "https://..." );'
Lastly, you can also see the URLs IXP Manager generates if logging is set to debug level in your var/log/YYYY/MM/YYYYMMDD.log files. Debug level is 7 and is set in application.ini. For example:

ondemand_resources.logger.enabled = 1
ondemand_resources.logger.writers.stream.level = 7
ondemand_resources.logger.writers.stream.path  = APPLICATION_PATH "/../var/log"
ondemand_resources.logger.writers.stream.owner = www-data
ondemand_resources.logger.writers.stream.group = www-data

An IXP assigns each customer (an) IP address(es) from the range used on the peering LAN(s). These IP addresses can show up in traceroutes (for example) and both IXPs and customers like to have these resolve to a hostname.

When creating *VLAN Interfaces* in IXP Manager there is a field called *IPv[4/6] Hostname*. This is intended for this DNS ARPA purpose. Some customers have specific requirements for these while other smaller customers may not fully understand the use cases. At INEX, we typically default to entries such as:

* `customer-name.v4.example.com` (where *example.com* would be *inex.ie* in our case)
* `customer-name.v6.example.com`

**IXP Manager** can generate your ARPA DNS entries for your peering IP space as per the hostnames configured on each VLAN interface and provide them in two ways:

* as JSON;
* as text based on a template (IXP Manager comes with a *ISC Bind* format example)

Both of these are explained below.

Note that the API endpoints below can be tested in your browser by directly accessing the URLs **when logged in**. Otherwise, you need an [API key](../dev/api.md) when using them in scripts.


## As JSON

You can use the **IXP Manager** API to get all ARPA entries for a given VLAN and protocol as a JSON object using the following endpoint format:

```
https://ixp.example.com/api/v4/dns/arpa/{vlanid}/{protocol}
```

where:

* `vlanid` is the database ID (*DB ID*) of the VLAN. You can find the DB ID in IXP Manager in the VLAN table (select *VLANs* from the left hand side menu).
* `protocol` is either `4` for IPv4 or 6 for `IPv6`.

If either of these are invalid, the API will return with a HTTP 404 response.

And example of the JSON response returned is:

```json
[
    {
        "enabled": true,
        "address": "192.0.2.67",
        "hostname": "cherrie.example.com",
        "arpa": "67.2.0.192.in-addr.arpa."
    },
    ...
]
```

where:

* `enabled` indicates if the protocol has been enabled for this user. This is nearly always true. A situation where it may be false is if you enabled IPv6 for a user; then that user subsequently decided to not use IPv6; then you unchecked the *IPv6 Enabled* box in the VLAN Interface form without removing address / hostname entries.
* `address` - this IPv4/6 address of the VLAN interface as assigned by the IXP.
* `hostname` - the configured hostname for this address as entered into **IXP Manager**.
* `arpa`: the generated ARPA record name for the IP address assigned by the IXP.

You can now feed the JSON object into a script to create your own DNS zones appropriate to your DNS infrastructure.

When scripting, we would normally pull the JSON object using something like:

```bash
#! /usr/bin/env bash

KEY="your-ixp-manager-api-key"
URL="https://ixp.example.com/api/v4/dns/arpa"
VLANIDS="1 2"
PROTOCOLS="4 6"

for v in $VLANIDS; do
    for p in $PROTOCOLS; do

        cmd="/usr/local/bin/curl --fail -s             \
            -H \"X-IXP-Manager-API-Key: ${KEY}\"       \
            ${URL}/${v}/${p}                           \
                >/tmp/dns-arpa-vlanid$v-ipv$p.json.$$"
        eval $cmd

        if [[ $? -ne 0 ]]; then
            echo "ERROR: non-zero return from DNS ARPA API call for vlan ID $v with protocol $p"
            continue
        fi

        // do something

        rm /tmp/dns-arpa-vlanid$v-ipv$p.json.$$
    done
done
```


## From Templates

Rather than writing your own scripts to consume the JSON object as above, it may be easier to use the bundled ISC Bind templates or to write your own template for IXP Manager.

You can use the **IXP Manager** API to get all ARPA entries for a given VLAN and protocol as plain text based on a template by using the following API endpoint:

```
https://ixp.example.com/api/v4/dns/arpa/{vlanid}/{protocol}/{template}
```

where:

* `vlanid` and `protocol` is as above in *As JSON*.
* `template` is the name of a template file residing in the view path `api/v4/dns/`.

Remember that the included ISC Bind templates can be [skinned](skinning.md) or you can add custom templates to your skin directory. More detail on this can be found in the dedicated section below.

The bundled ISC Bind templates can be used by setting `{template}` to `bind` or `bind-full` in the above URL. For the example interface in the JSON above, the ISC Bind `bind` template would yield:

```
67.2.0.192.in-addr.arpa.       IN   PTR     cherrie.example.com.
```

*(note that the terminated period on the hostname is added by the template)*

The two bundled templates are:

* `bind`: outputs resource records only as per the above example.
* `bind-full`: outputs a complete Bind zone file including head and serialized serial number (UNIX timestamp). This must be templated as it uses `example.com` for email and name server domains.

### Skinning / Templating

You can use [skinning](skinning.md) to make changes to the bundled ISC Bind template or add your own.

Let's say you wanted to add your own template called `mytemplate1` and your skin is named `myskin`. The best way to proceed is to copy the bundled example:

```sh
cd $IXPROOT
mkdir -p resources/skins/myskin/api/v4/dns
cp resources/views/api/v4/dns/bind.foil.php resources/skins/myskin/api/v4/dns/mytemplate1.foil.php
```

You can now edit this template as required. The only constraint on the template name is it can only contain characters from the classes `a-z, 0-9, -`. **NB:** do not use uppercase characters.

> **Contribute back** - if you write a useful generator, please open a pull request and contribute it back to the project.

The following variables are available in the template:

* `$t->arpa`: array of the ARPA entries - see below.
* `$t->vlan`: instance of the [`Vlan` entity object](https://github.com/inex/IXP-Manager/blob/master/database/Entities/Vlan.php).
* `$t->protocol`: either `4` or `6`.

The following variables are available for each element of the `$t->arpa` array (essentially the same as the JSON object above): `enabled, hostname, address, arpa`. See above for a description.

The actual code in the bundled ISC Bind sample is as simple as:

```php
<?php foreach( $t->arpa as $a ): ?>
<?= trim($a['arpa']) ?>    IN      PTR     <?= trim($a['hostname']) ?>.
<?php endforeach; ?>
```

### Sample Script

At INEX, we have (for example) one peering LAN that is a /25 IPv4 network and so is not a zone file in its own right. As such, we make up the zone file using includes. The main zone file looks like:

```
$TTL 86400

$INCLUDE /usr/local/etc/namedb/zones/soa-0.2.192.in-addr.arpa.inc

$INCLUDE zones/inex-dns-slave-nslist.inc

$INCLUDE zones/reverse-mgmt-hosts-ipv4.include
$INCLUDE zones/reverse-vlan-12-ipv4.include
```

The SOA file looks like (as you might expect):

```
@               IN      SOA     ns.example.come.     hostmaster.example.com. (
                        2017051701      ; Serial
                        43200           ; Refresh
                        7200            ; Retry
                        1209600         ; Expire
                        7200 )          ; Minimum
```

The `reverse-vlan-12-ipv4.include` is the output of the ISC Bind `bind` template above for a given VLAN ID.

We use the sample script `update-dns-from-ixp-manager.sh` which can be found [in this directory](https://github.com/inex/IXP-Manager/blob/master/tools/runtime/dns-arpa) to keep this updated ourselves.
