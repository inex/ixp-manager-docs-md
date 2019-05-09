# Users

???+ warning "**This page refers to a legacy version of IXP Manager (<v5.0)**"
    User management prior to v5.0 was handled differently - please see [this page](../users.md) for current usage.

The IXP Manager Users feature allows you to add and manage users (people who can login to IXP Manager) on a per customer basis including:

* name / email / phone number
* username
* permissions (see below)

## Types of Users

See the entity definitions [here](https://github.com/inex/IXP-Manager/blob/master/database/Entities/User.php).

There are three types of user:

* `AUTH_CUSTUSER` - a standard customer user with portal access to a specific customer's dashboard (`priv == 1`).
* `AUTH_CUSTADMIN` - a customer administrative user. The only purpose of this account is to allow customers to create, edit and remove their own users. No other access is available through a CUSTADMIN login (`priv == 2`).
* `AUTH_SUPERUSER` - IXP staff only. **FULL ACCESS TO ALL CUSTOMERS AND FUNCTIONS**. This is only for your IXP staff! (`priv == 3`)

There is a fourth internal permission but no user record exists for it:

* `AUTH_PUBLIC` - a visitor who has not logged into IXP Manager (`priv == 0`).

**Additional Historical Perspective:** the use of *AUTH_CUSTADMIN* was modeled on RIPE's equivalent model at the time. RIPE have since abandoned this model and it is our intention to do likewise.

## Welcome Email

**IXP Manager** sends a welcome email to all newly created users. The default template for this can be found at `resources/views/user/emails/welcome.blade.php`. If you wish to change this, you can do so via the [standard skinning mechanism](../../features/skinning.md).


## Logging in as Another User

Administrative users (*AUTH_SUPERUSER*) can *switch to* other users to *see what they see* via the user list or the customer overview page.

The purpose of this is for both development and for support staff to replicate issues as reported by users.

## Planned Work

As IXP Manager v5 evolves, we would like to make a number of changes:

* possibly remove usernames and have users log in with email addresses;
* allow a user to be associated with more than one customer;
* look at OAuth2 with links to PeeringDB as well as allowing people to log in / link OAuth supported social media accounts;
* rework the standard *CUSTUSER* and *CUSTADMIN* privileges into (perhaps) a read-only and a read-write model;
* add 2fa.

## Passwords and Password Hashing

Prior to **IXP Manager** v4.5, we supported both plaintext and bcrypt password hashing. There was a historical justification at INEX for support plaintext (this [may still be documented here](https://github.com/inex/IXP-Manager/wiki/Password-Hashing)). However, IXP Manager is meant to represent the best practices for managing IXP's. As such, plaintext support was removed in v4.5.

**As of v4.5, all passwords are stored as bcrypt with a cost >=10.**

Prior to **IXP Manager v4.9**, we allowed administrative users to set a user's password. This has been removed as we believe it to be bad practice - only a user should know their own password. User's can set (and reset) their passwords via their *Profile* page or using the password reset functionality.

## Historical Perspective

IXP Manager of pre-April 2013 had separate *contacts* and *users* which - at the time - we felt was quite confusing. [LONAP](http://www.lonap.net/) sponsored a rework of this in 2013 to merge the concept of users and contacts with login privileges. Strangely, this actually caused more confusion and also was a developer nightmare with hacked in code to handle the database tables in multiple places. As such, in 2019 with release v4.9, this was undone and contacts and users are now separate entities again.
