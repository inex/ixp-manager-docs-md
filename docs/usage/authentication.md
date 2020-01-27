# Authentication & Session Management

???+ note "**This page refers to features introduced in IXP Manager v5.3**"


## Session Management

IXP Manager allows users to login and remain logged in for up to 30 days (by default). Users may also have and maintain multiple login sessions from different browsers.

To enable such a session, the user must check the *Remember me* checkbox when logging in.

Active sessions can be seen (and deleted) via the *Active Sessions* option in the user's *My Account* menu (top right of screen).



## Two-Factor Authentication (2FA)

Two factor authentication (2FA) strengthens access security by requiring two methods (also referred to as factors) to verify your identity. Two factor authentication protects against phishing, social engineering and password brute force attacks and secures your logins from attackers exploiting weak or stolen credentials.

**IXP Manager** supports a Google Authenticator compatible HMAC-Based One-time Password (HOTP) algorithm as specified in [RFC 4226](https://tools.ietf.org/html/rfc4226) and the Time-based One-time Password (TOTP) algorithm specified in [RFC 6238](https://tools.ietf.org/html/rfc6238). In other words, *the standard* 2fa system that is support by most apps such as [Authy](https://www.authy.com/), Google Authenticator, [LastPass](https://lastpass.com/auth/), [1Password](https://1password.com/), etc.


User's can enable / view (and test) / disable 2fa via the *My Account -> Profile* page.

2FA is enabled by default (only for those users that have configured it). To globally disable it set the following `.env` option:

```
2FA_ENABLED=false
```

### Enforcing 2FA for Users

You can enforce the user of 2FA for some (or all) categories of users. Set the following configuration option:

```
2FA_ENFORCE_FOR_USERS=n
```

where *n* is the privilege level of the user (see `privs=` [here](users.md)). For example to force 2fa for:

* all superusers, set *n* to `3`;
* all custadmins and superusers, set *n* to `2`; or
* all users, set *n* to `1`.

If a user without 2fa enabled tries to login from a privilege category that has been configured to enforce 2fa, they will be required to configure 2fa immediately before being granted access to IXP Manager.

### Lifetime

A user will not be asked to revalidate their 2fa code during the lifetime of a session. 2fa lifetimes will be determined by the user's session. Remember that you can set the maximum session lifetime (see above) upon which time a user will need to revalidate with 2fa when logging back in.

### Recovery/Backup Codes

We have opted not to implement recovery / backup codes as they are not particularly appropriate to the scope of IXP Manager.

# Testing Issues

When enabling 2fa for the first time via the profile page:

1. I put in the wrong code a couple times to make sure it works before putting in the correct code. This cases an error (Action not allows) when I eventually put in the right one.
2. The Disable / Reset / Get 2FA QRcode buttons do not work as the JavaScript to determine the action cannot find the buttons. Don't think I broke it but I may have. The way you're doing it feels clunky - what about a per button listener to submit the form? Anyway, I just changed the form submit location manually to test.
