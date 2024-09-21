# Contacts

The **IXP Manager** *Contacts* feature allows you to record and manage contacts on a per customer basis including:

* name / position / email
* phone / mobile
* notes
* roles (billing / technical / admin / marketing)

If the roles are not shown when you are editing / adding contacts, ensure you copy the following file to a local version:

```sh
cp ${IXPROOT}/config/contact_group.php.dist ${IXPROOT}/config/contact_group.php
```

The latest version of the automatic installation script takes care of this but older versions did not.




## Contact Groups

Contacts can be assigned to multiple arbitrary groups. A group is defined by:

* a group type (e.g. *Marketing Preferences*);
* group options (e.g. *Email*, *SMS*, *Mail*, ...); and
* a description (e.g. *how the contact would like us to communicate marketing materials with them*).

You define the group types in `config/contact_group.php` such as:

```php
return [
    'types' => [
        'ROLE'                   => 'Role',
        'MARKETING_PREFERENCES'  => 'Marketing Preferences',
    ],
];
```

To activate this feature, you just need to create the configuration file. From the root directory of IXP Manager just:

```
cp config/contact_group.php.dist config/contact_group.php
```

Note that *Role* is a default option and should not be removed.

In these examples, `ROLE` will be entered in the database column and _Role_ will be displayed in the interface.

Group options can then be added / edited / deleted via the web interface. This can be reached by clicking *Contacts* in the left-hand side menu and then the sub-menu option that appears called *Contact Groups*.



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


Contact groups can be exported using the `artisan` command, for example:

```sh
./artisan contact:export-group --type=ROLE --cid=1 --format=csv
```

where the possible options are (from `./artisan contact:export-group --help`:

```
$ ./artisan contact:export-group --help
Usage:
  contact:export-group [options]

Options:
      --type[=TYPE]      Contact group type (e.g. ROLE)
      --name[=NAME]      Contact group name (e.g. beer)
      --format[=FORMAT]  Output format - one of json (default) or csv [default: "json"]
      --cid[=CID]        Optionally limit results to given customer id

Help:
  Export contacts based on group information
```


## Special Group: *Roles*

The default sample configuration file (`config/contact_group.php`) and the database seeds create a `ROLE` group type populated with groups *Admin*, *Billing*, *Technical* and *Marketing*. There is a dedicated form element when editing contacts for any groups defined in the Role type.

If the role type is removed from the configuration, the form element for the contact's roles will not be shown.


