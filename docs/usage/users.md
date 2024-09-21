# Users

The IXP Manager Users feature allows you to add and manage users (people who can login to IXP Manager) on a per customer basis including:

* name / email / phone number
* username
* permissions (see below)

For details on session management and two-factor authentication, please see [this page](authentication.md). For logging in with PeeringDB OAuth, please see [this page](../features/peeringdb-oauth.md).

## Types of Users

There are three types of user:

* **Customer User** - a standard customer user with **read only** portal access to a specific customer's dashboard (`privs = 1`).
* **Customer Administrator** - a customer administrative user. This account allows users to make changes as well as manage users for their organisation (`privs = 2`).
* **Superuser** - IXP staff only (`privs = 3`). **FULL ACCESS TO ALL CUSTOMERS AND FUNCTIONS**. This is only for your IXP staff!

## Managing Users

If you are a Superuser, you can manage users in one of two ways:

1. Via the user controller by clicking on *Users* under **IXP CUSTOMER ACTIONS** in the left hand menu. This will show all users on the system.
2. For a per customer view, you can click on the *Users* tab in the standard customer overview page.

If you are a customer administrator user, you can manage your own users via the *Users* menu in the top menu bar. In all cases, you will be given a list of users such as:

![User Management](img/user-mgmt.png)

The available actions include:

* a documentation link on the top right - that links to this page;
* to add a new user, click on the *[+]* button next to the documentation link;
* the view (eye) icon will show you more information about a specific user;
* the edit (pencil) icon will allow you to edit users;
* the delete (trashcan) icon will allow you to delete a user.


### Adding Users

Since a user can be associated with multiple customers, the new user you wish to add may already exist on the system. For this reason, the first step of adding a user is to just provide and email address:

![Adding Users](img/user-add.png)


If the user does not exist, you will be invited to complete the rest of the standard details:

![Adding Users](img/user-add-new.png)

Note that, as always, the *[Help]* button will provide context help for each input field. Once you successfully complete the details, the new user will be sent a welcome email ([see below for details](#welcome-email)) and invited to set their password.

If any users do exist with this email, you will be shown the user's name, username (and, if a superadmin, the other customer(s) the user is associated with). Note that it is possible for an email to be associated with more than one username but this should only happen for legacy users that predate the ability to assign a user to more than one customer.

![Adding Users](img/user-add-exists.png)

Select the user you wish to add to the customer and set the desired privilege and click *[Add User]*. The new user will be sent a specific welcome email for users that already exist on the system to let them know they have been added to a new customer account ([see below for details](#welcome-email)).


### Deleting Users

Note that *deleting* a user results in one of two actions:

1. if the user is only linked to a single customer (probably the most likely case), the user will be fully deleted and removed from the system.
2. if the user is linked to more than one customer, then only the link to this customer will be removed.


## Command Line User Management

There are three command line tools for managing users available since v6:

* `user:create`:  create a user.
* `user:find`: find and print user(s) details
* `user:set-password`: set the user's password

Here's a sample run of `user:set-password`:

```
❯ ./artisan user:set-password --search john
+-----+------------+------------+----------------+--------------+-------+
| ID  | Name       | Username   | Email          | Customers    | Privs |
+-----+------------+------------+----------------+--------------+-------+
| 115 | John Smith | sjohnsmith | js@example.com | Acme Limited | CA    |
| ... |            |            |                |              | CA    |
+-----+------------+------------+----------------+--------------+-------+

 Enter ID to change password for:
 > 115

 Password or (return to have one generated):
 >

Generated password: 1eHRUoDNiGBlkJEz
Password set.
```


## Users With Multiple Customers

This section explains the handling around users with multiple customers.

When logging in, the last customer that the user acted for will be selected. If this customer does not exist / the relationship no longer exists / no previous customer set then a customer will be chosen at random.

If a user is associated with more than one customer, then the facility to switch users can be found under the *My Account* menu on the top right:

![Switching Customers](img/users-switchto.png)

The current customer is highlighted.

## Welcome Email

**IXP Manager** sends a welcome email to all newly created users.

The default template for **new users** this can be found at `resources/views/user/emails/welcome.blade.php`. When an existing user is associated with an additional customer, the following template is used: `resources/views/user/emails/welcome-existing.blade.php`.


If you wish to change these templates, you can do so via the [standard skinning mechanism](../features/skinning.md).


## Logging in as Another User

Administrative users (*AUTH_SUPERUSER*) can *switch to* other users to *see what they see* via the user list or the customer overview page.

The purpose of this is for both development and for support staff to replicate issues as reported by users.


## Passwords and Password Hashing

All passwords are stored as bcrypt with a cost >=10.

Administrative users are unable to set a user's password. User's can set (and reset) their passwords via their *Profile* page or using the password reset functionality.
