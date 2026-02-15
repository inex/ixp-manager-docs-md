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

???+ note "**The default will be changed to disabled from IXP Manager v7.0.1.**"

Once you transition the clients consuming the APIs from the unsecured endpoints (`/api/v4`) to the secured endpoints (`/admin/api/v4`), you can disable the unsecured endpoints ahead of the v7.0.1 release via the *Authentication / Unsecured API Access Enabled* checkbox on the Settings frontend, or by setting the following in your `.env` file:

```
UNSECURED_API_ACCESS=0
```



