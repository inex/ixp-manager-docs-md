# IX-F Member List Export

The [IX-F Member Export](http://ml.ix-f.net/) is an agreed and standardized JSON schema which allows IXPs to make their member lists available for consumption by tools such as PeeringDB, networks with automated peering managers, prospective members and the many other tools appearing in the peering eco-system.

The key element of the IX-F Member Export is it makes you, the individual IXP, the canonical trusted source for data about *your own IXP*. Data that is guaranteed to be correct and up to date.

To find out more about the JSON schema and see examples, you can [explore any of the public IXP end points available here](http://ml.ix-f.net/directory) or see the GitHub [euro-ix/json-schemas](https://github.com/euro-ix/json-schemas) repository.

**IXP Manager** supports the IX-F Member List Export out of the box. It previously supported all versions from 0.3 to 0.5 but as of May 2017, we now only support 0.6 and 0.7. This is because these have become the stable common versions (as at time of writing, March 2018).

*Sometimes you may need something more customised than the the IX-F Member Export. For that, see [the other member export feature](member-export.md) if IXP Manager.*

## Accessing the IX-F Member List

If your version of IXP Manager is installed at, say, *https://ixp.example.com/*, then the IX-F Member List export can be accessed at:

```
https://ixp.example.com/api/v4/member-export/ixf/0.6
```

where *0.6* is a version parameter which allows for support of potential future versions.

Note that the publically accessable version does not include individiual member details such as name (ASN is provided), max prefixes, MAC addresses, contact email and phone, when the member joined, member's web address, peering policy, NOC website, NOC hours or member type. This information is available to any logged in users or users querying [the API with an API key](api.md).

## Registering Your API Endpoint

Register your IX-F Member List export on the [IXF Member List Directory Service](http://ml.ix-f.net/) at http://ml.ix-f.net/.

## Configuration Options

There is only one configuration option presently available. To disable public access to the restricted member export, set the following in your `.env` file:

```
IXP_API_JSONEXPORTSCHEMA_PUBLIC=false
```

**We strongly advise you not to disable public access if you are a standard IXP.** Remember, the public version is essentially the same list as you would provide on your standard website's list of members.

In addition, membership of an IXP is easily discernable from a number of other sources including:

* [PeeringDB](https://www.peeringdb.com)
* Route collectors (your own, PCH, members’ own, ...)
* Looking glasses
* Traceroutes (and tools such as: https://www.inex.ie/ard/ )
* RIPE RRC’s / RIS, RIPE Atlas
* Commercial products (Noction, ...)

Leave public access available, own your own data, ensure it's validy and advertise it!


## Example: Member Lists

A common requirement of IXPs is to create a public member list on their official website. This can be done with the IX-F Member Export quite easily. The below HTML and JavaScript is a way to do it with INEX's endpoint. There's a [live JSFiddle which demonstrates this also](https://jsfiddle.net/barryo/2tzuypf9/) - https://jsfiddle.net/barryo/2tzuypf9/ .

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

Company             | ASN         | Connections
--------------------|----------------------------------
3 Ireland           | 34218       | 2\*10Gb + 2\*10Gb
Afilias             | 12041       | 1Gb
...                 | ...         | ...
