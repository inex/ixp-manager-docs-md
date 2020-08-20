# TACACS (User Formatting)

**IXP Manager** can generate formatted lists of user information. The best example of this is for TACACS.

TACACS is used in most IXPs to manage access to switching and routing devices:

* to allow staff access to these devices with administrative privileges;
* to allow limited / full access to vendor support / TAC personnel;
* to allow member user access to services such as the route collector.

**IXP Manager** comes with a flexible template for generating the user section of a TACACS file.

## Generating TACACS Configuration

You can use the **IXP Manager** API to get the user section of a TACACS file using the following endpoint formats (both GET and POST requests work):

```
https://ixp.example.com/api/v4/user/formatted
https://ixp.example.com/api/v4/user/formatted/{priv}
https://ixp.example.com/api/v4/user/formatted/{priv}/{template}
```

where:

* `priv` is an optional user privilege to limit the user selection to. See [the available integer values on the `AUTH_` constants here](https://github.com/inex/IXP-Manager/blob/master/database/Entities/User.php). You typically want `3`.
* `template` is an optional template (rather than `$IXPROOT/resources/views/api/v4/user/formatted/default`). See below.

And example of a user in the response is:

```
user=joebloggs {
    member=admin
    login = des "$2y$10$pHln5b4DrPj3uuhgfg45HeWEQLK/3ngRxYgYppbnYzleJ.9EpLAN."
}
```

### Optional Parameters

You can optionally POST any of the following to change elements of the default template:

* `template`: only relevant when you want to specify a specific template without a privilege.
* `priv`: same as above.
* `users`: a comma-separated list of usernames to return rather than all / all based on privilege.
* `bcrypt`: IXP Manager stores bcrypt hashes with the prefix `2y`. Some systems, such as TACACS+ on FreeBSD, require `2a`. If you set `bcrypt=2a`, this substitution will be made before the data is returned.
* `group`: we put all users in the `admin` group in the default template. You can change that here.

An example of changing these parameters is:

```sh
curl --data "users=bob,alice&group=god&bcrypt=2a" -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "X-IXP-Manager-API-Key: my-ixp-manager-api-key" \
    https://ixpexample.com/api/v4/user/formatted
```


### Templates / Skinning

You can use [skinning](skinning.md) to make changes to the bundled `default` template or, **preferably**, add your own.

Let's say you wanted to add your own template called `mytemplate1` and your skin is named `myskin`. The best way to proceed is to copy the bundled example:

```sh
cd $IXPROOT
mkdir -p resources/skins/myskin/api/v4/user/formatted
cp resources/views/api/v4/user/formatted/default.foil.php resources/skins/myskin/api/v4/user/formatted/mytemplate1.foil.php
```

You can now edit this template as required. The only constraint on the template name is it can only contain characters from the classes `a-z, 0-9, -`. **NB:** do not use uppercase characters.

All variables available in the template can be [seen in the default template](https://github.com/inex/IXP-Manager/blob/master/resources/views/api/v4/user/formatted/default.foil.php).


## Setting Up TACACS

This section explains how to set up TACACS with IXP Manager. We assume you already have an understanding of TACACS.

### Generating / Updating TACACS

At INEX, we use a script that:

* includes the header and footer information for the conf file;
* pulls the user details from IXP Manager (specific users);
* validates the config;
* compares to current;
* reloads / restarts tac_plus if required.

You can find that script [in this directory](https://github.com/inex/IXP-Manager/tree/master/tools/runtime/tacacs). Alter it to suit your own purposes.
