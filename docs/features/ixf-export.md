# IX-F Member List Export

The [IX-F Member Export](http://www.ix-f.net/ixp-database.html) is an agreed and standardized JSON schema which allows IXPs to make their member lists available for consumption by tools such as [PeeringDB](https://www.peeringdb.com/), networks with automated peering managers, prospective members and the many other tools appearing in the peering eco-system.

> Historical reference: INEX created and hosted a proof of concept directory for the IX-F Export Schema until Euro-IX/IX-F took it in house in 2018.

The key element of the IX-F Member Export is it makes you, the individual IXP, the canonical trusted source for data about *your own IXP*. Data that has the best chance of being correct and up to date. Particularly, PeeringDB has the option of allowing network data to be updated from IX records - [see our documentation on this here](peeringdb.md#syncing-ixp-owned-data-to-peeringdb-customer-records).

To find out more about the JSON schema and see examples, you can [read more here](https://ixpdb.euro-ix.net/en/), [explore many of the public IXP end points available here](https://ixpdb.euro-ix.net/en/ixpdb/ixps/?reverse=&sort=name&q=&api=on) or see the GitHub [euro-ix/json-schemas](https://github.com/euro-ix/json-schemas) repository.

**IXP Manager** supports the IX-F Member List Export out of the box. It previously supported all versions from 0.3 to 0.5 but we now only support 0.6, 0.7 and 1.0 (for >=v5.1). We plan to deprecate support for 0.6 during 2019.

*Sometimes you may need something more customized than the the IX-F Member Export. For that, see [the other member export feature](member-export.md) if IXP Manager.*

## Preparing the IX-F Member Export

There are a small number of things you should do to ensure your IX-F export is correct.

**Correctly set the PeeringDB ID and IX-F ID**

The first is to ensure you have correctly set the PeeringDB ID and IX-F ID in your infrastructure (see *Infrastructures* under the left hand side *IXP ADMIN ACTIONS* menu).

The IX-F ID is mandatory. You will find yours by searching [the IX-F providers database here](https://ixpdb.euro-ix.net/en/ixpdb/providers/). If you are a new IXP that is not registered here, please email your IXP's: full name, short name, city / region / country, GPS co-ordinates and website URL to `ixpdb-admin (at) euro-ix (dot) net` so they can register it in the IXPDB.

**Create Network Info**

From **IXP Manager** v4.9 and above, click *VLANs* on the left-hand-side menu and then chose *Network Information*. Once there, add the network address and network mask length for IPv4 and IPv6 for your peering LAN(s).

Prior to v4.9, this was a little hacky: there is a database table called `networkinfo` that requires you to manually insert some detail on your peering LAN.

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
