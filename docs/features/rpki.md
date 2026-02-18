# RPKI

**IXP Manager** supports RPKI validation on the router configuration generated for Bird v2. The best way to fully understand RPKI with IXP Manager is to [watch our presentation](https://youtu.be/cqhJwuBaxxQ?t=1549) from APRICOT 2019 or [read this article](https://www.inex.ie/inex-news/shiny-new-route-servers/) on INEX's website.



## RPKI Validator / Local Cache

IXP Manager uses the RPKI-RTR protocol to feed ROAs to the Bird router instances. We recommend you install two of these validators/local caches from different vendors.

Let IXP Manager know where they are by setting the following `.env` settings:

```
# IP address and port of the first RPKI local cache:
IXP_RPKI_RTR1_HOST=192.0.2.11
IXP_RPKI_RTR1_PORT=3323

# While not required, we recommend you also install a second validator:
# IXP_RPKI_RTR2_HOST=192.0.2.12
# IXP_RPKI_RTR2_PORT=3323
```


See our installation notes for these:

1. [Routinator 3000](rpki/routinator.md).
2. [rpki-client](rpki/rpkiclient.md).
3. ~~[Cloudflare's RPKI Toolkit](rpki/cloudflare.md)~~ - *this has now been [deprecated](https://github.com/cloudflare/cfrpki/commit/932c7596bb6f8ce2e0dadd7930e19ddef1beab0e) and should not be used*.
4. ~~[RIPE NCC RPKI Validator 3](./rpki/ripe.md)~~ - *this has now been [deprecated](https://www.ripe.net/publications/news/ending-support-for-the-ripe-ncc-rpki-validator/) and should not be used*.


## BIRD RPKI Settings

BIRD has the following RPKI RTR settings:

```
min version num

    Minimal allowed version of the RTR protocol. BIRD will refuse to downgrade a 
    connection below this version and drop the session instead. Default: 0

max version num

    Maximal allowed version of the RTR protocol. BIRD will start with this version. 
    Use this option if sending version 2 to your cache causes problems. Default: 2 
```

To allow you to set these without skinning the templates, there are new settings UI/.env options as follows:

```
IXP_RPKI_RTR1_MIN_VERSION=0
IXP_RPKI_RTR1_MAX_VERSION=2
IXP_RPKI_RTR2_MIN_VERSION=0
IXP_RPKI_RTR2_MAX_VERSION=2
```


## Enabling RPKI

The outline procedure to enable RPKI is below. These notes are written from the perspective that you have existing IXP Manager Bird v1 route servers. If this is a green field site, these notes will work just as well by ignoring the upgrade bits. **In either case, it's vital you already understand [how to configure routers in IXP Manager](routers.md).**

At INEX we started with our route collector which is a non-service affecting administrative tool. Once we were happy with the stability and results of that, we upgraded our two route servers one week apart in planned announced maintenance windows. We also took the opportunity to perform a distribution upgrade from Ubuntu 16.04 to 18.04.

Start by installing two local caches / validator services as linked above. INEX uses Cloudflare's and Routinator 3000. You should also add these to your production monitoring service.

Once your maintenance window starts, stop the target route server you plan to upgrade. You'll then need to to remove the Bird v1 package (`dpkg -r bird` on Ubuntu). Once the Bird package is removed, you can perform a distribution upgrade if you wish.

Bird v2 is available as a prebuilt package with Ubuntu 20.04 LTS and can be installed with `apt install bird2`.

There are no Bird v2 packages for Ubuntu 18.04 LTS. As such, you need to install from source if using that older platform. Rather than installing a build environment and compiling on each server, you can do this on a single server (a dedicated build box / admin server / etc) and then distribute the package across your route servers / collector:

```sh
# Install Ubuntu build packages and libraries Bird requires:
apt install -y build-essential libssh-dev libreadline-dev \
    libncurses-dev flex bison checkinstall

# At time of writing, the latest release was v2.0.7.
# Check for newer versions!
cd /usr/src
wget ftp://bird.network.cz/pub/bird/bird-2.0.7.tar.gz
tar zxf  bird-2.0.7.tar.gz
cd bird-2.0.7/
./configure  --prefix=/usr --sysconfdir=/etc
make -j2
checkinstall -y
```

The `checkinstall` tool creates a deb package file: `/usr/local/src/bird-2.0.7/bird_2.0.7-1_amd64.deb`

**NB: for this method to work, you must be running the same operating system and version on the target servers as the build box.** For us, it was Ubuntu 18.04 LTS on all systems.

To install on a target machine:

```sh
# from build machine
scp bird_2.0.7-1_amd64.deb target-machine:/tmp

# on target machine
apt install -y libssh-dev libreadline-dev libncurses-dev
dpkg -i /tmp/bird_2.0.7-1_amd64.deb
```

You now need to update your route server record in IXP Manager:

* set *Software* to *Bird v2* (this is currently informational only);
* check *Enable RPKI filtering*;
* update the template to `api/v4/router/server/bird2/standard`.

Note that the Bird v2 template uses large BGP communities extensively internally. The option *Enable Large BGP Communities / RFC8092* only controls whether your members can use large communities for filtering. *It's 2020 - you should really enable this.*

As mentioned above, you need to let IXP Manager know where your local caching / validators are by setting the following `.env` settings:

```
# IP address and port of the first RPKI local cache:
IXP_RPKI_RTR1_HOST=192.0.2.11
IXP_RPKI_RTR1_PORT=3323

# While not required, we recommend you also install a second validator:
IXP_RPKI_RTR2_HOST=192.0.2.12
IXP_RPKI_RTR2_PORT=3323
```

Take a look at the generated configuration within IXP Manager now and sanity check it.

If you have been using [our scripts](https://github.com/inex/IXP-Manager/tree/release-v5/tools/runtime/route-servers) to reload route server configurations, you will need to download [the new one](https://github.com/inex/IXP-Manager/blob/release-v5/tools/runtime/route-servers/api-reconfigure-example-birdv2.sh) (and edit the lines at the top) or update your existing one. The main elements that need to be changed is that the daemon name is not longer named differently for IPv6 (Bird v1 had `bird/birdc` and `bird6/bird6c` where as Bird v2 only has `bird/birdc`).

You should now be able to run this script to pull a new configuration and start an instance of the route server. We would start with one and compare route numbers (just eyeball them) against the route server you have not upgraded.

You're nearly there! If you are using our [Bird's Eye looking glass](looking-glass.md), you will need to upgrade this to >= v1.2.1 for Bird v2 support. At INEX, we tend to clone the repository and so a simple `git pull` is all that's required. If you're installing from release packages, get the latest one and copy over your configurations.

## Bird Operational Notes

These notes are valid when using IXP Manager's Bird v2 with RPKI route server configuration.

You can see the status of the RPKI-RTR protocol with:

```
bird> show protocols "rpki*"
Name       Proto      Table      State  Since         Info
rpki1      RPKI       ---        up     2019-05-11 14:51:40  Established
rpki2      RPKI       ---        up     2019-05-11 12:44:25  Established
```

And you can see detailed information with:

```
bird> show protocols all rpki1
Name       Proto      Table      State  Since         Info
rpki1      RPKI       ---        up     2019-05-11 14:51:40  Established
  Cache server:     10.39.5.123:3323
  Status:           Established
  Transport:        Unprotected over TCP
  Protocol version: 1
  Session ID:       54059
  Serial number:    122
  Last update:      before 459.194 s
  Refresh timer   : 440.805/900
  Retry timer     : ---
  Expire timer    : 172340.805/172800
  Channel roa4
    State:          UP
    Table:          t_roa
    Preference:     100
    Input filter:   ACCEPT
    Output filter:  REJECT
    Routes:         72161 imported, 0 exported
    Route change stats:     received   rejected   filtered    ignored   accepted
      Import updates:         141834          0          0          0     141834
      Import withdraws:         2519          0        ---          0       3367
      Export updates:              0          0          0        ---          0
      Export withdraws:            0        ---        ---        ---          0
  No roa6 channel
```

You can examine the ROA table with:

```
bird> show route table t_roa
Table t_roa:
58.69.253.0/24-24 AS36776  [rpki1 2019-05-11 14:51:40] * (100)
                           [rpki2 2019-05-11 12:45:45] (100)
```

Now, using INEX's route collector ASN (`2128`) as an example here - change for your own collector/server ASN - you can find RPKI invalid and filtered routes via:

```
bird> show route  where bgp_large_community ~ [(2128,1101,13)]
Table master4:
136.146.52.0/22      unicast [pb_as15169_vli99_ipv4 2019-05-11 01:00:17] * (100) [AS396982e]
        via 185.6.36.57 on eth1
...
```

At time of writing, the filtered reason communities are:

```
define IXP_LC_FILTERED_PREFIX_LEN_TOO_LONG      = ( routeserverasn, 1101, 1  );
define IXP_LC_FILTERED_PREFIX_LEN_TOO_SHORT     = ( routeserverasn, 1101, 2  );
define IXP_LC_FILTERED_BOGON                    = ( routeserverasn, 1101, 3  );
define IXP_LC_FILTERED_BOGON_ASN                = ( routeserverasn, 1101, 4  );
define IXP_LC_FILTERED_AS_PATH_TOO_LONG         = ( routeserverasn, 1101, 5  );
define IXP_LC_FILTERED_AS_PATH_TOO_SHORT        = ( routeserverasn, 1101, 6  );
define IXP_LC_FILTERED_FIRST_AS_NOT_PEER_AS     = ( routeserverasn, 1101, 7  );
define IXP_LC_FILTERED_NEXT_HOP_NOT_PEER_IP     = ( routeserverasn, 1101, 8  );
define IXP_LC_FILTERED_IRRDB_PREFIX_FILTERED    = ( routeserverasn, 1101, 9  );
define IXP_LC_FILTERED_IRRDB_ORIGIN_AS_FILTERED = ( routeserverasn, 1101, 10 );
define IXP_LC_FILTERED_PREFIX_NOT_IN_ORIGIN_AS  = ( routeserverasn, 1101, 11 );
define IXP_LC_FILTERED_RPKI_UNKNOWN             = ( routeserverasn, 1101, 12 );
define IXP_LC_FILTERED_RPKI_INVALID             = ( routeserverasn, 1101, 13 );
define IXP_LC_FILTERED_TRANSIT_FREE_ASN         = ( routeserverasn, 1101, 14 );
define IXP_LC_FILTERED_TOO_MANY_COMMUNITIES     = ( routeserverasn, 1101, 15 );
```

Check the route server configuration as generated by IXP Manager for the current list.

If you want to see if a specific IP is covered by a ROA, use:

```
bird> show route table t_roa where 45.114.234.0 ~ net
Table t_roa:
45.114.234.0/24-24 AS59347  [rpki1 2019-05-11 14:51:40] * (100)
                            [rpki2 2019-05-11 12:45:45] (100)
45.114.232.0/22-24 AS59347  [rpki1 2019-05-11 14:51:40] * (100)
                            [rpki2 2019-05-11 12:45:45] (100)
45.114.232.0/22-22 AS59347  [rpki1 2019-05-11 14:51:41] * (100)
                            [rpki2 2019-05-11 12:45:45] (100)
```
