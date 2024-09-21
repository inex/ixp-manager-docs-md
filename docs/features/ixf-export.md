# IX-F Member List Export

The [IX-F Member Export](http://www.ix-f.net/ixp-database.html) is an agreed and standardized JSON schema which allows IXPs to make their member lists available for consumption by tools such as [PeeringDB](https://www.peeringdb.com/), networks with automated peering managers, prospective members and the many other tools appearing in the peering eco-system.

> Historical reference: INEX created and hosted a proof of concept directory for the IX-F Export Schema until Euro-IX/IX-F took it in house in 2018.

The key element of the IX-F Member Export is it makes you, the individual IXP, the canonical trusted source for data about *your own IXP*. Data that has the best chance of being correct and up to date. Particularly, PeeringDB has the option of allowing network data to be updated from IX records - [see our documentation on this here](peeringdb.md#syncing-ixp-owned-data-to-peeringdb-customer-records).

To find out more about the JSON schema and see examples, you can [read more here](https://ixpdb.euro-ix.net/en/), [explore many of the public IXP end points available here](https://ixpdb.euro-ix.net/en/ixpdb/ixps/?reverse=&sort=name&q=&api=on) or see the GitHub [euro-ix/json-schemas](https://github.com/euro-ix/json-schemas) repository.

**IXP Manager** supports versions 0.6, 0.7 and 1.0 of the IX-F Member List Export.

*Sometimes you may need something more customized than the the IX-F Member Export. For that, see [the other member export feature](member-export.md) if IXP Manager.*

## Preparing the IX-F Member Export

There are a small number of things you should do to ensure your IX-F export is correct.

**Correctly set the PeeringDB ID and IX-F ID**

The first is to ensure you have correctly set the PeeringDB ID and IX-F ID in your infrastructure (see *Infrastructures* under the left hand side *IXP ADMIN ACTIONS* menu).

The IX-F ID is mandatory. You will find yours by searching [the IX-F providers database here](https://ixpdb.euro-ix.net/en/ixpdb/providers/). If you are a new IXP that is not registered here, please email your IXP's: full name, short name, city / region / country, GPS coordinates and website URL to `ixpdb-admin (at) euro-ix (dot) net` so they can register it in the IXPDB.

**Create Network Info**

Click *VLANs* on the left-hand-side menu and then chose *Network Information*. Once there, add the network address and network mask length for IPv4 and IPv6 for your peering LAN(s).

The first thing you need is the peering VLAN DB ID. *[clarification note: this is nothing to do with PeeringDB but the VLAN created within IXP Manager].* For this, select *VLANs* under the left hand side *IXP ADMIN ACTIONS* menu in IXP Manager. Locate your peering VLAN *DB ID* and note it.

For our example, we will use the following sample data:

* Peering VLAN *DB ID*: 66
* IPv4 peering network: `192.0.2.0/25` with route servers on `.8` and `.9`
* IPv6 peering network: `2001:db8:1000::/64` with route servers on `.8` and `.9`

You need need to add this data to `networkinfo` with the following sample SQL commands:

```mysql
INSERT INTO `networkinfo`
    ( `vlanid`, `protocol`, `network`, `masklen`, `rs1address`, `rs2address`),
VALUES
    ( 66, 4, '192.0.2.0', '25', '192.0.2.8', '192.0.2.9' );

INSERT INTO `networkinfo`
    ( `vlanid`, `protocol`, `network`, `masklen`, `rs1address`, `rs2address`),
VALUES
    ( 66, 6, '2001:db8:1000::', '64', '2001:db8:1000::8', '2001:db8:1000::9' );

```


**Set Your IXP's Name / Country / etc**

The third task is to ensure your IXP's details are correct in the IX-F export.

You will most likely have nothing to do here as it would have been done on installation but this reference may prove useful if there are any issues.

These are mostly set in the `.env` file (as well as some other places) and the following table shows how they get mapped to the IX-F Export:

IX-F Export IXP Element   | How to Set in IXP Manager
--------------------------|---------------------------------------------------------------
`shortname`               | In IXP Manager, from the *Infrastructure* object name field
`name`                    | `IDENTITY_LEGALNAME` from `.env`
`country`                 | `IDENTITY_COUNTRY` from `.env` **in 2-letter ISO2 format**
`url`                     | `IDENTITY_CORPORATE_URL` from `.env`
`peeringdb_id`            | In IXP Manager, from the *Infrastructure* object
`ixf_id`                  | In IXP Manager, from the *Infrastructure* object
`support_email`           | `IDENTITY_SUPPORT_EMAIL` from `.env`
`support_phone`           | `IDENTITY_SUPPORT_PHONE` from `.env`
`support_contact_hours`   | `IDENTITY_SUPPORT_HOURS` from `.env`
`emergency_email`         | `IDENTITY_SUPPORT_EMAIL` from `.env`
`emergency_phone`         | `IDENTITY_SUPPORT_PHONE` from `.env`
`emergency_contact_hours` | `IDENTITY_SUPPORT_HOURS` from `.env`
`billing_email`           | `IDENTITY_BILLING_EMAIL`
`billing_phone`           | `IDENTITY_BILLING_PHONE`
`billing_contact_hours`   | `IDENTITY_BILLING_HOURS`

We we say *from the Infrastructure object* above, we mean that when you are logged into IXP Manager as an admin, it's the *Infrastructures* menu option under *IXP Admin Actions* on the left hand side.



## Accessing the IX-F Member List

If your version of IXP Manager is installed at, say, *https://ixp.example.com/*, then the IX-F Member List export can be accessed at:

```
https://ixp.example.com/api/v4/member-export/ixf/1.0
```

where *1.0* is a version parameter which allows for support of potential future versions.

Note that the publicly accessible version does not include individual member details such as name, max prefixes, contact email and phone, when the member joined, member's web address, peering policy, NOC website, NOC hours or member type. This information is available to any logged in users or users querying [the API with an API key](api.md).


### Access Without IX-F ID Being Set

While the IX-F ID is officially required for >= v0.7 of the schema, it may be overlooked on new installations or some IXPs may be uninterested in working with the IX-F IXP database.

The schema requirement for a valid IX-F ID should not prevent the IX-F exporter from working if someone wishes to pull the information regardless of that being set. There are two ways to override this and query the API:

The first is to pass an `ixfid_y` parameter (where `y` is the database ID of the infrastructure) **every** infrastructure that does not have one. Using this method will have IXP Manager set the IX-F ID in the generated JSON output suitable for processing by automated scripts. A sample URL for an IXP with two infrastructures might look like this:

```
https://ixpmanager.example.com/api/v4/member-export/ixf/1.0?ixfid_1=30&ixfid_2=31
```

If you wish to just ignore the IX-F ID and have it set to zero in the JSON output, you can use the following flag:

```
https://ixpmanager.example.com/api/v4/member-export/ixf/1.0?ignore_missing_ixfid=1
```

## Registering Your API Endpoint With IXPDB

IXPDB requires two pieces of information to fully integrate with the IXPDB. You can provide this information to `ixpdb-admin (at) euro-ix (dot) net` or - if you have a login to the Euro-IX website, you should be able to login and edit your own IXP directly on IXPDB.

The first element needed is the API endpoint as described above in *Accessing the IX-F Member List*.

The second is the API endpoint to export your statistics. This is:

```
https://ixp.example.com/grapher/infrastructure?id=1&type=log&period=day
```

where `id=1` is the infrastructure DB ID (see *Infrastructures* under the left hand side *IXP ADMIN ACTIONS* menu).

## Configuration Options

To disable public access to the restricted member export, set the following in your `.env` file:

```
IXP_API_JSONEXPORTSCHEMA_PUBLIC=false
```

**We strongly advise you not to disable public access if you are a standard IXP.** Remember, the public version is essentially the same list as you would provide on your standard website's list of members.

In addition, membership of an IXP is easily discernible from a number of other sources including:

* [PeeringDB](https://www.peeringdb.com)
* Route collectors (your own, PCH, members’ own, ...)
* Looking glasses
* Traceroutes (and tools such as: https://www.inex.ie/ard/ )
* RIPE RRCs / RIS, RIPE Atlas
* Commercial products (Noction, ...)

Leave public access available, own your own data, ensure it's validity and advertise it!

If you must disable public access but would still like to provide IX-F (or others) with access, you can set a static access key in your `.env` file such as:

```
IXP_API_JSONEXPORTSCHEMA_ACCESS_KEY="super-secret-access-key"
```

and then provide the URL in the format:

```
https://ixp.example.com/api/v4/member-export/ixf/1.0?access_key=super-secret-access-key
```


If you wish to control access to the infrastructure statistics, see [the Grapher API documentation](../grapher/api.md). The statistics data is a JSON object representing each line of [a *the rest of the file* from a standard MRTG log file](https://oss.oetiker.ch/mrtg/doc/mrtg-logfile.en.html). This means the per-line array elements are:

1. The Unix timestamp for the point in time the data on this line is relevant.
2. The average incoming transfer rate in bytes per second. This is valid for the time between the A value of the current line and the A value of the previous line.
3. The average outgoing transfer rate in bytes per second since the previous measurement.
4. The maximum incoming transfer rate in bytes per second for the current interval. This is calculated from all the updates which have occurred in the current interval. If the current interval is 1 hour, and updates have occurred every 5 minutes, it will be the biggest 5 minute transfer rate seen during the hour.
5. The maximum outgoing transfer rate in bytes per second for the current interval.


### Excluding Some Data

It is possible to exclude some data per [GitHub issue #722](https://github.com/inex/IXP-Manager/issues/722):

> While some exchanges are willing to share detailed information about their infrastructure via the IX-F Member Export Schema, others either do not want to or cannot due to regulation. Enabling exchanges to share a limited set of data about their infrastructure would help exchanges find others using the same platforms to learn from each other and shows the diversity of platforms in use across the market.

???+ important "Please bear in mind that the more data you remove, the less useful the IX-F member export becomes. Most IXPs do not use this exclusion function and, ideally, you will only use it if there is no other choice."


For example, a switch object typically looks like:

```json
{
    "id": 50,
    "name": "swi1-kcp1-2",
    "colo": "Equinix DB2 (Kilcarbery)",
    "city": "Dublin",
    "country": "IE",
    "pdb_facility_id": 178,
    "manufacturer": "Arista",
    "model": "DCS-7280SR-48C6",
    "software": "EOS 4.24.3M"
}
```

If, for example, you need to exclude the model and software version, you can add the following to your `.env` file:

```
IXP_API_JSONEXPORTSCHEMA_EXCLUDE_SWITCH="model|software"
```

which will yield:

```json
{
    "id": 50,
    "name": "swi1-kcp1-2",
    "colo": "Equinix DB2 (Kilcarbery)",
    "city": "Dublin",
    "country": "IE",
    "pdb_facility_id": 178,
    "manufacturer": "Arista"
}
```

As you can see, the configuration option is the set of identifiers you want to exclude (`model` and `software`) separated with the pipe symbol. Different combinations are possible - here are some examples:

```
IXP_API_JSONEXPORTSCHEMA_EXCLUDE_SWITCH="software"
IXP_API_JSONEXPORTSCHEMA_EXCLUDE_SWITCH="model|software"
IXP_API_JSONEXPORTSCHEMA_EXCLUDE_SWITCH="city|model|software"
```

You **should not** exclude the `id` as these is referred to in the member interface list.

You can exclude detail for the IXP object:

```json
{
    "shortname": "INEX LAN1",
    "name": "Internet Neutral Exchange Association Limited by Guarantee",
    "country": "IE",
    "url": "https:\/\/www.inex.ie\/",
    "peeringdb_id": 48,
    "ixf_id": 20,
    "ixp_id": 1,
    "support_email": "operations@example.com",
    "support_contact_hours": "24x7",
    "emergency_email": "operations@example.com",
    "emergency_contact_hours": "24x7",
    "billing_contact_hours": "8x5",
    "billing_email": "accounts@example.com",
    ...
}
```

with the option:

```
IXP_API_JSONEXPORTSCHEMA_EXCLUDE_IXP="name|url"
```

You **should not** exclude any of the IDs (`peeringdb_id`, `ixf_id` and `ixp_id`) as these is referred to else where in the document and required externally when using the data.

You can exclude member detail:

```json
{
    "asnum": 42,
    "member_since": "2009-01-13T00:00:00Z",
    "url": "http:\/\/www.pch.net\/",
    "name": "Packet Clearing House DNS",
    "peering_policy": "open",
    "member_type": "peering",
    ...
}
```

with the option:

```
IXP_API_JSONEXPORTSCHEMA_EXCLUDE_MEMBER="peering_policy|member_type"
```

And finally, you can include member VLAN/protocol detail:

```json
"ipv4": {
    "address": "185.6.36.60",
    "as_macro": "AS-PCH",
    "routeserver": true,
    "mac_addresses": [
        "00:xx:yy:11:22:33"
    ],
    "max_prefix": 2000
},
"ipv6": {
    "address": "2001:7f8:18::60",
    "as_macro": "AS-PCH",
    "routeserver": true,
    "mac_addresses": [
        "00:xx:yy:11:22:33"
    ],
    "max_prefix": 2000
}
```

with the option:

```
IXP_API_JSONEXPORTSCHEMA_EXCLUDE_INTINFO="mac_addresses|routeserver"
```

Please note that the `IXP_API_JSONEXPORTSCHEMA_EXCLUDE_INTINFO` affects **both** the ipv4 and ipv6 clauses.


### Excluding Members

You can exclude members by ASN or by [tag](../usage/customer-tags.md) by setting the following `.env` option:

```
# Exclude members with certain AS numbers
# IXP_API_JSONEXPORTSCHEMA_EXCLUDE_ASNUM="65001|65002|65003"

# Exclude members with certain tags
# IXP_API_JSONEXPORTSCHEMA_EXCLUDE_TAGS="tag1|tag2"
```

The following are enabled by default to prevent exporting test customers:

```
# Exclude documentation ASNs (64496 - 64511, 65536 - 65551)
# IXP_API_JSONEXPORTSCHEMA_EXCLUDE_RFC5398=true

# Exclude private ASNs (64512 - 65534, 4200000000 - 4294967294)
# IXP_API_JSONEXPORTSCHEMA_EXCLUDE_RFC6996=true
```




### Including IXP Manager Specific Data

If you pass `withtags=1` as a parameter to the URL endpoint, then you will get an extra section in each member section:

```json
"ixp_manager": {
    "tags": {
        "exampletag1": "Example Tag #1",
        "exampletag2": "Example Tag #2"
    },
    "in_manrs": false,
    "is_reseller": false,
    "is_resold": true,
    "resold_via_asn": 65501
},
```

As you can see:

* Any [tags](../usage/customer-tags.md) you have assigned to a member will get listed. If you are accessing the IF-X export while logged in as a super user (or using a superuser API key) then it will also include internal tags.
* `is_manrs` indicates if the member is [MANRS compliant](manrs.md).
* `is_reseller` indicates if this member is a [reseller](reseller.md).
* `is_resold` indicates if the member has come via a reseller and, if so, `resold_via_asn` provides the AS number of the reseller.


## Example: Member Lists

A common requirement of IXPs is to create a public member list on their official website. This can be done with the IX-F Member Export quite easily. The below HTML and JavaScript is a way to do it with INEX's endpoint. There's a [live JSFiddle which demonstrates this also](https://jsfiddle.net/barryo/2tzuypf9/) - [https://jsfiddle.net/barryo/2tzuypf9/](https://jsfiddle.net/barryo/2tzuypf9/).

The HTML requires just a table with a placeholder and an `id` on the `body`:

```html
<table class="table table-bordered" style="margin: 10px">
 <thead>
   <tr>
     <th>Company</th>
     <th>ASN</th>
     <th>Connections</th>
   </tr>
 </thead>
 <tbody id="list-members">
     <tr>
         <td colspan="3">Please wait, loading...</td>
     </tr>
 </tbody>
</table>
```

The JavaScript loads the member list via the IX-F Export and processes it into the table above:

```js
// Sample IX-F Member Export to Member List script
//
// License: MIT (https://en.wikipedia.org/wiki/MIT_License)
// By @yannrobin and @barryo
// 2018-03-06

function prettySpeeds( s ) {
        switch( s ) {
            case 10:     return "10Mb";
            case 100:    return "100Mb";
            case 1000:   return "1Gb";
            case 10000:  return "10Gb";
            case 40000:  return "40Gb";
            case 100000: return "100Gb";
        default:     return s;
    }
}

$.getJSON( "https://www.inex.ie/ixp/api/v4/member-export/ixf/0.7", function( json ) {

      // sort by name
    json[ 'member_list' ].sort( function(a, b) {
        var nameA = a.name.toUpperCase(); // ignore upper and lowercase
        var nameB = b.name.toUpperCase(); // ignore upper and lowercase
        if (nameA < nameB) {
          return -1;
        }
        if (nameA > nameB) {
          return 1;
        }
        // names must be equal
        return 0;
    });

    let html = '';

    $.each( json[ 'member_list' ], function(i, member) {
        html += `<tr>
                     <td>
                         <a target="_blank" href="${member.url}">${member.name}</a>
                     </td>
                     <td>
                         <a target="_blank"
                             href="http://www.ripe.net/perl/whois?searchtext=${member.asnum}&form_type=simple">
                             ${member.asnum}
                         </a>
                     </td>`;

        let connection = '';
        $.each( member[ 'connection_list' ], function(i, conn ) {
            if( conn[ 'if_list' ].length > 1 ){
                  connection += conn[ 'if_list' ].length+ '*'
            }
            connection += prettySpeeds( conn[ 'if_list' ][0].if_speed );

            if(i < (member[ 'connection_list' ].length - 1 )){
              connection += " + ";
            }
        });

        html += `<td>${connection}</td></tr>\n`;
    });

    $( "#list-members" ).html(html);
});
```

The end result is a table that looks like:

Company             | ASN         | Connections        |
--------------------|----------------------------------|
3 Ireland           | 34218       | 2\*10Gb + 2\*10Gb  |
Afilias             | 12041       | 1Gb                |
...                 | ...         | ...                |
