# Mailing List Management

**IXP Manager** has the ability to allow users to subscribe / unsubscribe from Mailman mailing lists (it should be relatively easy to expand this to other mailing list managers as the functionality is based on Mailman but not Mailman specific).

The following sections explain the steps in how this is set up.

**NB:** This facility does not perform a 100% synchronisation. Any mailing list members that are added separately without a matching user in IXP Manager are not interfered with.

## Configuring Available Mailing Lists

There is a sample configuration file which you need to copy as follows:

```sh
cd $IXPROOT
cp config/mailinglists.php.dist config.mailinglists.php
```

You then need to edit this file as follows:

1. Enable the mailing list functionality by setting this to true:

    ```php
    // Set the following to 'true' to enable mailing list functionality:
    'enabled' => true,
    ```

    If this is not set to true, the user will not be offered subscription options and the CLI commands will not execute.

2. Configure the available mailing list(s) in the `lists` array. Here is an example:

    ```php
    'lists' => [
        'members' => [
            'name'    => "Members' Mailing List",
            'desc'    => "A longer description as presented in IXP Manager.",
            'email'   => "members@example.com",
            'archive' => "https://www.example.com/mailman/private/members/",
            'syncpws' => false,
        ],
        'tech' => [
            'name'    => "Tech/Operations Mailing List",
            'desc'    => "A longer description as presented in IXP Manager.",
            'email'   => "tech@example.com",
            'archive' => "https://www.example.com/mailman/private/tech/"
            'syncpws' => false,
        ],
    ],

    ```

    Note that the `members` and `tech` array keys above are the list handles that will be used by the API interfaces later. It is also important that they match the Mailman list key.

    Historically, mailing list passwords were also sync'd from the IXP Manager user database *unless* `syncpws` is both defined and false for the given list. As we are now recommending *bcrypt* as the standard password hashing mechanism, we not longer recommend this and suggest allowing Mailman to manage its own passwords.

3. Paths to Mailman commands. These will be used in the API/CLI elements later:

    ```php
    'mailman' => [
        'cmds' => [
            'list_members'   => "/usr/local/mailman/bin/list_members",
            'add_members'    => "/usr/local/mailman/bin/add_members -r - -w n -a n",
            'remove_members' => "/usr/local/mailman/bin/remove_members -f - -n -N",
            'changepw'       => "/usr/local/mailman/bin/withlist -q -l -r changepw"
        ]
    ]
    ```


## Explanation of Usage

This mailing list synchronisation / integration code was written for existing Mailman lists we have at INEX where some lists are public with subscribers that will never have an account on INEX's IXP Manager. As such, these scripts are written so that email addresses in common between IXP Manager and Mailman can manage their subscriptions in IXP Manager but those other subscribers will be unaffected.

Users in IXP Manager will either be marked as being subscribed to a list, not subscribed to a list or neither (i.e. a new user). Subscriptions are managed by user preferences (in the database) of the format:

```
mailinglist.listname1.subscribed = 0/1
```

There are four steps to performing the synchronisation **for each list** which are done by either using the IXP Manager CLI script `$IXPROOT/bin/ixptool.php` or the older [API V1](https://github.com/inex/IXP-Manager/wiki/API-V1) interface.

### CLI Interface Overview

1. The execution of the `mailing-list-cli.list-init` script which is really for new IXP Manager users (or initial set up of the mailing list feature). This script is piped the full subscribers list from Mailman (via `list_members`). This function will iterate through all users and, if they have no preference set for subscription to this list, will either add a "not subscribed" preference if their email address is not in the provided list of subscribers or a "subscribed" preference if it is.

2. The execution of the `mailing-list-cli.get-subscribed` action which lists all users who are subscribed to the given mailing list based on their user preferences. This is piped to the `add_members` Mailman script.

3. The execution of the `mailing-list-cli.get-unsubscribed` action which lists all users who are unsubscribed to the given mailing list based on their user preferences. This is piped to the `remove_members` Mailman script.

4. The execution of the `mailing-list-cli.password-sync` action which sets the mailing list password for  all users who are unsubscribed to the given mailing list based on their IXP Manager user password. This action `exec()`'s' the change password command directly. **See Password Synchronisation below.** Unlike the above three operations, the password sync executes a command directly (via PHP `exec()`). If you just want to print the commands to stdout, add the parameters `-v -p noexec=1`.

### API V1 Interface Overview

The CLI version of mailing list management was presented above. If you wish to use the API version, proceed as follows where:

* `$MyKey` is one of your SUPERUSER API keys;
* `https://www.example.com/ixp/` is your IXP Manager web interface;
* `members` is an example mailing list handle as defined above in `$IXPROOT/config/mailinglists.php`.


Use the initialisation function for new IXP Manager users (or initial set up of the mailing list feature) which updates IXP Manager with all currently subscribed mailing list members:

```sh
/path/to/mailman/bin/list_members members >/tmp/ml-listname1.txt
curl -f --data-urlencode addresses@/tmp/ml-listname1.txt \
    "https://www.example.com/ixp/apiv1/mailing-list/init/key/$MyKey/list/members"
rm /tmp/ml-listname1.txt
```

Pipe all subscribed users to the `add_members` Mailman script:

```sh
curl -f "https://www.example.com/ixp/apiv1/mailing-list/get-subscribed/key/$MyKey/list/members" | \
    /path/to/mailman/bin/add_members -r - -w n -a n members >/dev/null
```

Pipe all users who are unsubscribed to the `remove_members` Mailman script:

```sh
curl -f "https://www.example.com/ixp/apiv1/mailing-list/get-unsubscribed/key/$MyKey/list/members" | \
    /path/to/mailman/bin/remove_members -f - -n -N members >/dev/null
```

Sync the passwords from IXP Manager to Mailman with something like:

```sh
curl -f "https://www.example.com/ixp/apiv1/mailing-list/password-sync/key/MyKey/list/listname1" | \
    egrep "^/path/to/mailman/bin/withlist -q -l -r changepw '.+' '.+' '.+'$" | /bin/sh >/dev/null
```

*(Feel free to make the above regexp more secure and update this document).*        


## How to Implement

You can implement mailing list management by configuring IXP Manager as above.

IXP Manager will then generate shell scripts to manage all of the above.

Execute the following command for the CLI version:

```sh
bin/ixptool.php -a mailing-list-cli.sync-script >bin/mailing-list-sync.sh
```

Or the following for the API V1 version **(and make sure to update the assignments at the top of the script)**:

```sh
bin/ixptool.php -a mailing-list-cli.sync-script --p1=apiv1 >bin/mailing-list-sync-apiv1.sh
```

This generates a script called `mailing-list-sync[-apiv1].sh` which performs each of the above four steps for each configured mailing list. If your mailing list configuration does not change, you will not need to rerun this.

You should now put this script into crontab on the appropriate server (same server for CLI!) and run as often as you feel is necessary. The current *success* message for a user updating their subscriptions says *within 12 hours* so we'd recommend at least running twice a day.


## Password Synchronisation

**We now recommend against this [for the reasons explained here](https://github.com/inex/IXP-Manager/wiki/Password-Hashing). We have not investigated if Mailman can support Bcrypt as of yet.**

By default, passwords from IXP Manager users with mailing list subscriptions will be sync'd to Mailman.

This is done via the Mailman `withlist` script and it requires a `changepw.py` script to be in the same directory as `withlist` and this script is not supplied by default (although it is documented). Create the following `changepw.py` in the same directory as `withlist`:

```py
from Mailman.Errors import NotAMemberError

def changepw(mlist, addr, newpasswd):
    try:
        mlist.setMemberPassword(addr, newpasswd)
        mlist.Save()
    except NotAMemberError:
        print 'No address matched:', addr
```

## Todo

* better handling of multiple users with the same email address and documentation of same
* user changes email address
