# Looking Glass

IXP Manager supports full looking glass features when using the Bird BGP daemon and [Bird's Eye](https://github.com/inex/birdseye) *(a simple secure micro service for querying Bird)*.

A fully working example of this can be seen [here on INEX's IXP Manager](https://www.inex.ie/ixp/lg).

Enabling the looking glass just requires:

1. properly configured [router(s)](routers.md).
2. *Bird's Eye* installed on these.
3. the API endpoint must be accessible from the server running IXP Manager and this endpoint must be set correctly in the router's configuration (see [router(s)](routers.md) page) (along with an appropriate setting for *LG Access Privileges*). Note that the Birdseye API end points do not need to be publicly accessible - just from the IXP Manager server.
4. set the `.env` option: `IXP_FE_FRONTEND_DISABLED_LOOKING_GLASS=false` (in IXP Manager's `.env` and add it if it's missing as it defaults to `true`).


## Example Router Configuration

See this screenshot for an appropriately configured INEX router with Bird's Eye:

![Router Configuration for LG](img/lg-router-conf.png)

## Debugging

The API endpoint must be accessible from the server running IXP Manager. Changing the URL as appropriate, test and confirm this with something like:

```sh
wget -O - http://as112-lan1-ipv4.example.com/api/status
```

which should give a status response (we've made the JSON formatting readable here):

```json
{
    "api": {
        "from_cache":false,
        "version":"1.1.0",
        "max_routes":1000
    },
    "status": {
        "version":"1.6.3",
        "router_id":"192.0.2.45",
        "server_time":"2017-09-12T14:25:49+00:00",
        "last_reboot":"2017-05-21T16:02:30+00:00",
        "last_reconfig":"2017-09-12T14:12:00+00:00",
        "message":"Daemon is up and running"
    }
}
```
