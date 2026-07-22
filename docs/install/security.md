# IXP Manager Security

## Securing Administrative Functions

IXP Manager has always been both an administrative portal for organisations that run IXPs and a member/customer portal for the participants at an IXP. This creates a security paradox in that IXP Manager's administrative frontend must be publicly available if IXPs wish to provide the customer portal element. 

To address this, v7.1.0 has prepended all administrative-only URLs, both web and api, with `admin/`. This will allow IXP administrators to restrict access to these prepended URLs to known-safe IP addresses via web server access lists, for which [we provide examples for Varnish, Apache and Nginx here](./security/securing-admin.md).

### Transition Settings

Prepending web requests with `/admin` should not cause any issues. However, IXPs that consume a number of the API endpoints may not be able to repoint them all to their newer `/admin` versions in a single maintenance window. 

For this reason, IXP Manager v7.1.0 will ship with these API endpoints available under both `/api/v4/...` and `/admin/api/v4/...`. Any requests to `/api/v4/...` will be logged and these can be grepped as follows:

```sh
/srv/ixpmanager $ cat storage/logs/laravel.log | grep grep 'UNPREPENDED/DEPRECATED'
[2026-02-15 10:10:20] local.NOTICE: UNPREPENDED/DEPRECATED usage of API request api/v4/nagios/switches/2 from 127.0.0.1
[2026-02-15 10:27:01] local.NOTICE: UNPREPENDED/DEPRECATED usage of API request api/v4/router/gen-config/as112-cork-ipv4 from 127.0.0.1
[2026-02-15 10:27:07] local.NOTICE: UNPREPENDED/DEPRECATED usage of API request api/v4/router/gen-config/as112-lan1-ipv4 from 127.0.0.1
```

You can further refine this to something like:

```sh
/srv/ixpmanager $ cat storage/logs/laravel.log | grep 'UNPREPENDED/DEPRECATED' | awk '{print $11 "\t" $9}' | uniq -c
   4 127.0.0.1	api/v4/nagios/switches/2
   1 127.0.0.1	api/v4/router/gen-config/as112-cork-ipv4
   1 127.0.0.1	api/v4/router/gen-config/as112-lan1-ipv4
```

???+ note "**The default will be changed to disabled in the next minor release.**"

Once you transition the clients consuming the APIs from the unsecured endpoints (`/api/v4`) to the secured endpoints (`/admin/api/v4`), you can disable the unsecured endpoints ahead of the next minor release via the *Authentication / Unsecured API Access Enabled* checkbox on the Settings frontend, or by setting the following in your `.env` file:

```
UNSECURED_API_ACCESS=0
```

## API Key as GET Parameter

As of v7.3.0 IXP Manager has started generating warnings in log files about use of API Keys via GET parameters. This practice is discouraged as
GET parameters are included in webserver logs by default. As such, support for this feature will be turned off by default in v7.4.0.

You can search for ongoing usage of this authentication method:

```sh
/srv/ixpmanager $ cat storage/logs/laravel.log | grep 'API KEY in GET'
[2026-07-20 17:19:20] vagrant.NOTICE: DEPRECATED usage of API Key in GET parameter (API Key ID: 2): api/v4/test from ::1
[2026-07-20 17:19:20] vagrant.NOTICE: DEPRECATED usage of API Key in GET parameter (API Token Identifier: iqLw1OF50aPU): api/v4/test from ::1
```

And analyse usage of API keys in this way using the following command which outputs 1) the number of occurrences, 2) the api key ID for legacy keys, or the token identifier for new API keys, 3) the URI fragment, and 4) the IP address which originated the request.

```sh
/srv/ixpmanager $ grep 'API Key in GET' storage/logs/laravel.log  | sed -E 's/.*\(([^:]*:\s*)?([^)]*)\):\s*([^ ]+)\s+from\s+(.*)/\2\t\3\t\4/' | sort | uniq -c
      1 14	api/v4/test	127.0.0.1
      4 2	api/v4/test	::1
     24 6	api/v4/test	127.0.0.1
      1 7	api/v4/test	127.0.0.1
     26 	api/v4/test	127.0.0.1
     52 iqLw1OF50aPU	api/v4/test	127.0.0.1
```

Once you have updated any integrations, you can disable the practice entirely ahead of the next minor release via the *Authentication / Allow API authentication via GET parameter* checkbox on the Settings frontend, or by setting the following in your `.env` file:

```
IXP_ALLOW_DEPRECATED_APIKEYS_VIA_GET=0
```
