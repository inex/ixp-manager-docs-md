# Authentication & Session Management

???+ note "**This page refers to features introduced in IXP Manager v5.3**"


## Session Management

IXP Manager allows users to login and remain logged in for up to 30 days (by default). Users may also have and maintain multiple login sessions from different browsers.

To enable such a long-lived session, the user must check the *Remember me* checkbox when logging in.

Active sessions can be seen (and deleted) via the *Active Sessions* option in the user's *My Account* menu (top right of screen).


### Session Lifetimes

There are two configurable options here - **both in minutes**. The first is the session lifetime which is how long a browser session will stay valid since the last activity. The default value is defined in `.env` as:

```
SESSION_LIFETIME=120
```

In other words, your login session (when you do not check *remember me*) will stay valid for 120 minutes / 2 hours by default. This is two hours *since the last request* - i.e. the session expiry time updates on each request. If you are curious, the browser cookie managing this is called `laravel_session` by default.


If the user checks *remember me*, then a second cookie is sent to and stored on your browser (called `remember_web_xxx` where `xxx` is a random string). This references an entry in the user's `user_remember_tokens` database table.

The default lifetime of this *remember me* session is defined in `.env` as:

```
AUTH_TOKEN_EXPIRE=43200
```

So, your *remember me* session will last 30 days before you will be forced to login again from a particular browser.

You may notice that the cookie sent to the browser for this has an indefinite lifetime - the expiry is actually controlled by the `user_remember_tokens.expires` database column.

## Two-Factor Authentication (2FA)

Two factor authentication (2FA) strengthens access security by requiring two methods (also referred to as factors) to verify your identity. Two factor authentication protects against phishing, social engineering and password brute force attacks and secures your logins from attackers exploiting weak or stolen credentials.

**For the avoidance of doubt, 2fa does not apply to API keys or API requests. Treat your API keys with extreme care.**

**IXP Manager** supports a Google Authenticator compatible HMAC-Based One-time Password (HOTP) algorithm as specified in [RFC 4226](https://tools.ietf.org/html/rfc4226) and the Time-based One-time Password (TOTP) algorithm specified in [RFC 6238](https://tools.ietf.org/html/rfc6238). In other words, *the standard* 2fa system that is supported by most apps such as [Authy](https://www.authy.com/), Google Authenticator, [LastPass](https://lastpass.com/auth/), [1Password](https://1password.com/), etc.

User's can enable, view (and test) and disable 2fa via the *My Account -> Profile* page.

2FA support in IXP Manager is enabled by default from v5.3. To globally disable it set the following `.env` option:

```
2FA_ENABLED=false
```

### Enforcing 2FA for Users

You can enforce the use of 2FA for some (or all) categories of users. Set the following configuration option:

```
2FA_ENFORCE_FOR_USERS=n
```

where *n* is the privilege level of the user (see `privs=` [here](users.md)). For example to force 2fa for:

* all superusers, set *n* to `3`;
* all custadmins and superusers, set *n* to `2`; or
* all users, set *n* to `1`.

If a user without 2fa enabled tries to login from a privilege category that has been configured to enforce 2fa, they will be required to configure 2fa immediately before being granted access to IXP Manager.

### Lifetime

A user will not be asked to revalidate their 2fa code during the lifetime of a standard browser session or *remember me* session (see above).

### Removing 2fa / Restoring User Access

We have opted not to implement recovery / backup codes as they are not particularly appropriate to the scope of IXP Manager.

If a user needs to have their 2fa removed (indefinitely or so they can reconfigure it), superadmins can do this via the standard user listing (the *Users* option in the left hand menu).

Identity the user you wish to remove 2fa from, dropdown the additional actions menu on the far right of the table row and select *Remove 2FA*.

Once you confirm this action, that user's 2fa configuration will be deleted. The next time they log in, they will either be granted access without 2fe or forced to reconfigure 2fa if you have enforced 2fa for the user's category.
