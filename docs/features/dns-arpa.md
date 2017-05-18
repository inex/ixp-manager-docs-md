# DNS / ARPA

An IXP assigns each customer (an) IP address(es) from the range used on the peering LAN(s). These IP addresses can show up in traceroutes (for example) and both IXPs and customers like to have these resolve to a hostname.

When creating *VLAN Interfaces* in IXP Manager there is a field called *IPv[4/6] Hostname*. This is intended for this DNS ARPA purpose. Some customer have specific requirements for these while other smaller customers may not fully understand the use cases. At INEX, we typically default to entries such as:

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
