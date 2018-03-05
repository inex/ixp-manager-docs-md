# Member Export

The recommended means of exporting member details from IXP Manager is to use the [IX-F Member Export](ixf-export.md) tool. We even provide examples of how to use this to create example tables.

However, you may sometimes require additional flexibility which necessitates rolling your own export templates. This *Member Export* feature will allow you to do this *but it does require some PHP programming ability*.

This *Member Export* feature is modeled after the [static content](static-content.md) tool and you are advised to read that page also.

*This feature first appears in v4.8.0 and replaces the [deprecated older way of handling this](https://github.com/inex/IXP-Manager/wiki/Exporting-Member-Details).*

## Overview

In IXP Manager, there are four types of users as described [in the users page](../usage/users.md). Member export templates can be added which requires a minimum user privilege to access (e.g. `priv == 0` would be publicly accessible through to `priv == 3` which would require a superadmin).

To create your own member export templte, you should first [set up skinning](skinning.md) for your installation. Let's assume you called your skin `example` in the following.

To create a publicly accessible member export page called `lonap`, you would first create a directory structure in your skin as follows:

```sh
cd ${IXPROOT}
mkdir -p resources/skins/example/content/members/{0,1,2,3}
```

where the directories `0, 1, 2, 3` represent the *minimum required user privilege* to access the template. You can now create your export template page by creating a file:

```sh
resources/skins/example/content/members/0/lonap.foil.php
```

and then edit that page. In fact, we have bundled three examples in the following locations:

1. `resources/skins/example/content/members/3/lonap.foil.php`: a table that replicates how LONAP have traditionally listed their members ([see here](https://www.lonap.net/members.shtml)). It would be accessed via: https://ixp.example.com/content/members/3/lonap
1. `resources/skins/example/content/members/3/json-example.foil.php`: a JSON example of the above. The HTTP response content type is set to JSON with `.json` is added to the URL. However you have to ensure your template outputs JSON also. This would be accessed via: https://ixp.example.com/content/members/3/json-example.json
1. `resources/skins/inex/content/members/0/list.foil.php`: what we at INEX use to generate [this members list](https://www.inex.ie/about-us/inex-members/). You can access the real data via: https://www.inex.ie/ixp/content/members/0/list.json (not that this is publicly accessible).

The format of the URL to access these member export templates is:

```
https://ixp.example.com/content/members/{priv}/{page}[.json]
```

* `{priv}` is the *minimum required user privilege* required to access the page and is used first for testing the user's permissions and second as the directory to check for the file.
* `{page}` is the name of the file to load (less `.foil.php`) and **please be aware that this is normalised as follows:**
```php
preg_replace( '/[^a-z0-9\-_]/', '', strtolower( $page ) )
```
i.e. the file name can only contain characters from the class `[a-z0-9\-_]` and all lower case.
* `[.json]` is an optional extension which tells IXP Manager to set the `Content-Type: application/json` header in the response.
