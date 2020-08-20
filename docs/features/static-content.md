# Static Content

**IXP Manager** can serve some static pages for you if you wish. The typical use cases for this are:

1. support details / contact page;
2. other static content relevant to your members.

## Overview

In IXP Manager, there are four types of users as described [in the users page](../usage/users.md). Static contact can be added which requires a minimum user privilege to access (e.g. `priv == 0` would be publicly accessible through to `priv == 3` which would require a superadmin).

To create static content, you should first [set up skinning](skinning.md) for your installation. Let's assume you called your skin `example`.

To create a publicly accessible static content page called `misc-benefits`, you would first create a content directory in your skin as follows:

```sh
cd $IXPROOT
mkdir -p resources/skins/example/content/{0,1,2,3}
```

where the directories `0, 1, 2, 3` represent the *minimum required user privilege* to access the content. You can now create your content page as follows:

```sh
cp resources/views/content/0/example.foil.php resources/skins/example/content/0/misc-benefits.foil.php
```

and then edit that page.

It can be accessed using a URL such as: `https://ixp.example.com/content/0/misc-benefits` where the route template is: `content/{priv}/{page}`.

* `{priv}` is the *minimum required user privilege* required to access the page and is used first for testing the user's permissions and second as the directory to check for the file.
* `{page}` is the name of the file to load (less `.foil.php`) and **please be aware that this is normalised as follows:**
```php
preg_replace( '/[^a-z0-9\-_]/', '', strtolower( $page ) )
```
i.e. the file name can only contain characters from the class `[a-z0-9\-_]` and all lower case. *Prior to v4.8.0 the `strtolower()` mistakenly occurred after the `preg_replace()`.*


The `example.foil.php` template copied above should provide the necessary structure for you. Essentially just replace the title and the content.

For publicly accessible documents, there is an alias route:

```
/public-content/{page}  -> treated as: /content/0/{page}
```

## Support / Contact Template

IXP Manager ships with a link to *Support* in the main title menu. You should copy and adjust this as necessary via skinning:

```sh
cp resources/views/content/0/support.foil.php resources/skins/example/content/0/support.foil.php
```

## Documentation Menu

You can link to your own static contact pages using the *Documentation* menu by skinning this file:

```sh
cp resources/views/header-documentation.foil.php resources/skins/example/header-documentation.foil.php
```

The stock version includes a link to the example page and a external link to the IXP Manager website *(we would be much obliged if you left this in place!)*.

INEX's own version of this can be found in the shipped `resources/skins/inex/header-documentation.foil.php` file which shows how we use it.
