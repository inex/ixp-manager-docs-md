# Contacts

The **IXP Manager** *Contacts* feature allows you to record and manage contacts on a per customer basis including:

* name / position / email
* phone / mobile
* notes
* roles (billing / techical / admin / marketing)

If the roles are not shown when you are editing / adding contacts, ensure you copy the following file to a local version:

```sh
cp ${IXPROOT}/config/contact_group.php.dist ${IXPROOT}/config/contact_group.php
```

The latest version of the automatic installation script takes care of this but older versions did not.



## Contact Groups

**INTRODUCED:** 20130410 - V3.0.9 (sponsored by [LONAP](http://www.lonap.net/))

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

Note that *Role* is a default option and should not be removed.

In these examples, `ROLE` will be entered in the database column and _Role_ will be displayed in the interface.

Group options can then be added / edited / deleted via the web interface. This can be reached by clicking *Contacts* in the left-hand side menu and then the sub-menu option that appears called *Contact Groups*.

## Assigning Contacts to Groups

Assigning contacts to groups is done in the contact add / edit page.


## Exporting Contact Groups

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


## Historical Perspective

IXP Manager of pre-April 2013 had separate *contacts* and *users* which - at the time - we felt was quite confusing. [LONAP](http://www.lonap.net/) sponsored a rework of this in 2013 to merge the concept of users and contacts with login privileges. Strangely, this actually caused more confusion and also was a developer nightmare with hacked in code to handle the database tables in multiple places. As such, in 2019 with release v4.9, this was undone and contacts and users are now separate entities again.
