# Contact Groups

Contacts can now be assigned to multiple arbitrary groups.

## Activating the Configuration

Your database will already be set-up via the database seeds during installation.

To activate this feature, you just need to create the configuration file. From the root directory of IXP Manager just::

```
cp config/contact_group.php.dist config/contact_group.php
```

## Creating / Editing / Deleting Groups

A group is defined by:

* a name (e.g. beer);
* a type (e.g. Likes); and
* a description (e.g. Contacts in this group like to drink beer).

You define the group types in `config/contact_group.php`.

In these examples, `ROLE` will be entered in the database column and *Role* will be displayed in the interface.

Groups can then be added / edited / deleted via `https://www.example/com/ixp-manager/contact-group`. This can be reached by clicking *Contacts* and then *Contact Groups* in the left menu.

## Assigning Contacts to Groups

Assigning contacts to groups is done in the contact add / edit page.

## Exporting Contact Groups

Contact groups can be exported using the `ixptool.php` command, for example::
```
bin/ixptool.php -a cli.cli-export-group -p type=ROLE,format=csv,cid=1
```

where the possible comma separated parameters are:

* `type=XXX`: Contact group type (e.g. ROLE); or
* `name=XXX`: Contact group name (e.g. beer).

* `format=XXX`: Output format - one of json (default) or csv
* `sn`: Customer shortname to limit results to; or
* `cid`: Customer id to limit results to.

## Special Group: *Roles*

The default sample configuration file (`config/contact_group.php`) and the database seeds create a `ROLE` group type populated with groups *Admin*, *Billing*, *Technical* and *Marketing*. There is a dedicated form element when editing contacts for any groups defined in the Role type.

If the role type is removed from the configuration, the form element for the contact's roles will not be shown.
