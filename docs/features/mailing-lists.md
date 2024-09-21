# Mailing List Management

**IXP Manager** has the ability to allow users to subscribe / unsubscribe from Mailman mailing lists (it should be relatively easy to expand this to other mailing list managers as the functionality is based on Mailman but not Mailman specific).

The following sections explain the steps in how this is set up.

**NB:** This facility does not perform a 100% synchronisation. Any mailing list members that are added separately without a matching user in IXP Manager are not interfered with.

## Configuring Available Mailing Lists

There is a sample configuration file which you need to copy as follows:

```sh
cd $IXPROOT
cp config/mailinglists.php.dist config/mailinglists.php
```

You then need to edit this file as follows:

1. Enable the mailing list functionality by setting this to true:

    ```php
    // Set the following to 'true' to enable mailing list functionality:
    'enabled' => true,
    ```

    If this is not set to true, the user will not be offered subscription options and the CLI/API commands will not execute.

2. Configure the available mailing list(s) in the `lists` array. Here is an example:

    ```php
    'lists' => [
        'members' => [
            'name'    => "Members' Mailing List",
            'desc'    => "A longer description as presented in IXP Manager.",
            'email'   => "members@example.com",
            'archive' => "https://www.example.com/mailman/private/members/",
        ],
        'tech' => [
            'name'    => "Tech/Operations Mailing List",
            'desc'    => "A longer description as presented in IXP Manager.",
            'email'   => "tech@example.com",
            'archive' => "https://www.example.com/mailman/private/tech/",
        ],
    ],

    ```

    Note that the `members` and `tech` array keys above are the list handles that will be used by the API interfaces later. It is also important that they match the Mailman list key.

    Historically, mailing list passwords were also sync'd from the IXP Manager user database *unless* `syncpws` is both defined and false for the given list. As we are now enforcing *bcrypt* as the standard password hashing mechanism, we no longer support this and suggest allowing Mailman to manage its own passwords.

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

There are three steps to performing the synchronisation **for each list** which are done by either using the IXP Manager CLI script `artisan mailing-list:...` or the [API](api.md) interface.

### CLI Interface Overview

1. The execution of the `artisan mailing-list:init` script which is really for new IXP Manager users (or initial set up of the mailing list feature). This script is piped the full subscribers list from Mailman (via `list_members`). This function will iterate through all users and, if they have no preference set for subscription to this list, will either add a "not subscribed" preference if their email address is not in the provided list of subscribers or a "subscribed" preference if it is.

2. The execution of the `artisan mailing-list:get-subscribers` action which lists all users who are subscribed to the given mailing list based on their user preferences. This is piped to the `add_members` Mailman script.

3. The execution of the `artisan mailing-list:get-subscribers --unsubscribed` action which lists all users who are unsubscribed to the given mailing list based on their user preferences. This is piped to the `remove_members` Mailman script.

### API V4 Interface Overview

If you wish to use the API version, proceed as follows where:

* `$KEY` is one of your SUPERUSER API keys (see [here](api.md) for details);
* `https://ixp.example.com` is your IXP Manager web interface;
* `members` is an example mailing list handle as defined above in `$IXPROOT/config/mailinglists.php`.


Use the initialisation function for new IXP Manager users (or initial set up of the mailing list feature) which updates IXP Manager with all currently subscribed mailing list members:

```sh
/path/to/mailman/bin/list_members members >/tmp/ml-members.txt
curl -f --data-urlencode addresses@/tmp/ml-members.txt \
    -H "X-IXP-Manager-API-Key: $KEY" -X POST
    "https://ixp.example.co/api/v4/mailing-list/init/members"
rm /tmp/ml-members.txt
```

Pipe all subscribed users to the `add_members` Mailman script:

```sh
curl -f -H "X-IXP-Manager-API-Key: $KEY" -X GET \
    "https://ixp.example.co/api/v4/mailing-list/subscribers/members" | \
    /path/to/mailman/bin/add_members -r - -w n -a n members >/dev/null
```

Pipe all users who are unsubscribed to the `remove_members` Mailman script:

```sh
curl -f -H "X-IXP-Manager-API-Key: $KEY" -X GET \
    "https://ixp.example.co/api/v4/mailing-list/unsubscribed/members" | \
    /path/to/mailman/bin/remove_members -f - -n -N members >/dev/null
```

## How to Implement

You can implement mailing list management by configuring IXP Manager as above.

IXP Manager will generate shell scripts to manage all of the above.

Execute the following command for the CLI version **(and make sure to update the assignments at the top of the script)**:

```sh
artisan mailing-list:sync-script --sh
```

Or the following for the API V4 version **(and make sure to update the assignments at the top of the script)**:

```sh
artisan mailing-list:sync-script
```

This generates a script which performs each of the above four steps for each configured mailing list. If your mailing list configuration does not change, you will not need to rerun this.

You should now put this script into crontab on the appropriate server (same server for CLI!) and run as often as you feel is necessary. The current *success* message for a user updating their subscriptions says *within 12 hours* so we'd recommend at least running twice a day.



## Todo

* better handling of multiple users with the same email address and documentation of same
* user changes email address

