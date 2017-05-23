# Users & Contacts

## Historical Perspective

IXP Manager's database schema has been in use in production at INEX since the mid-2000's. Since then, how users are represented in web-based applications has evolved and we have some work to do on IXP Manager in this regard.

IXP Manager of pre-April 2013 had separate *contacts* and *users* which was quite confusing. [LONAP](http://www.lonap.net/) sponsored a rework of this and now all users are contacts with login privileges. The interface still allows listing of these separately but all links for adding / editing / deleting will *do the right thing*.

As IXP Manager v4 evolves, we would like to make a number of changes:

* reconsider the need for *users* and *contacts* - can these be collapsed to one table, be split again or stay as is;
* remove usernames and have users log in with email addresses;
* allow a user to be associated with more than one customer;
* look at OAuth2 with links to PeeringDB as well as allowing people to log in / link OAuth supported social media accounts;
* rework the standard *CUSTUSER* and *CUSTADMIN* privileges into (perhaps) a read-only and a read-write model;
* add 2fa.


## Types of Users

See the entity definitions [here](https://github.com/inex/IXP-Manager/blob/master/database/Entities/User.php).

There are four types of user:

* `AUTH_PUBLIC` - a visitor who has not logged into IXP Manager.
* `AUTH_CUSTUSER` - a standard customer user with portal access.
* `AUTH_CUSTADMIN` - a customer administrative user. The only purpose of this account is to allow customers to create, edit and remove their own users. No other access is available through a CUSTADMIN login.
* `AUTH_SUPERUSER` - IXP staff only. **FULL ACCESS TO ALL CUSTOMERS AND FUNCTIONS**. This is only for your IXP staff!

**Additional Historical Perspective:** the use of *AUTH_CUSTADMIN* was modeled on RIPE's equivalent model at the time. RIPE have since abandoned this model and it is our intention to do likewise.

## Logging in as Another User

Administrative users (*AUTH_SUPERUSER*) can *switch to* other users to *see what they see* via the user list or the customer overview page.

The purpose of this is for both development and for support staff to replicate issues as reported by users.

## Password Hashing

Prior to **IXP Manager** v4.5, we supported both plaintext and bcrypt password hashing. There was a historical justification at INEX for support plaintext (this [may still be documented here](https://github.com/inex/IXP-Manager/wiki/Password-Hashing)). However, IXP Manager is meant to represent the best practices for managing IXP's. As such, plaintext support was removed in v4.5.

**As of v4.5, all passwords are stored as bcrypt with a cost >=10.**
