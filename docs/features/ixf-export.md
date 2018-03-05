# IX-F Member List Export

The [IX-F Member Export](http://ml.ix-f.net/) is an agreed and standardized JSON schema which allows IXPs to make their member lists available for consumption by tools such as PeeringDB, networks with automated peering managers, prospective members and the many other tools appearing in the peering eco-system.

The key element of the IX-F Member Export is it makes you, the individual IXP, the canonical trusted source for data about *your own IXP*. Data that is guaranteed to be correct and up to date.

To find out more about the JSON schema and see examples, you can [explore any of the public IXP end points available here](http://ml.ix-f.net/directory) or see the GitHub [euro-ix/json-schemas](https://github.com/euro-ix/json-schemas) repository.

**IXP Manager** supports the IX-F Member List Export out of the box. It previously supported all versions from 0.3 to 0.5 but as of May 2017, we now only support 0.6 and 0.7. This is because these have become the stable common versions (as at time of writing, March 2018).

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
