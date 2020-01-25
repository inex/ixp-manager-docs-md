# Authentication & Session Management

???+ note "**This page refers to features introduced in IXP Manager v5.3**"


## Session Management

IXP Manager allows users to login and remain logged in for up to 30 days (by default). Users may also have and maintain multiple login sessions from different browsers.

To enable such a session, the user must check the *Remember me* checkbox when logging in.

Active sessions can be seen (and deleted) via the *Active Sessions* option in the user's *My Account* menu (top right of screen).



## Two-Factor Authentication (2FA)


### Lifetime

A user will not be asked to revalidate their 2fa code during the lifetime of a session. 2fa lifetimes will be determined by the user's session. Remember that you can set the maximum session lifetime (see above) upon which time a user will need to revalidate with 2fa when logging back in.

### Recovery/Backup Codes

We have opted not to implement recovery / backup codes as they are not particularly appropriate to the scope of IXP Manager.

# Testing Issues

When enabling 2fa for the first time via the profile page:

1. I put in the wrong code a couple times to make sure it works before putting in the correct code. This cases an error (Action not allows) when I eventually put in the right one.
2. The Disable / Reset / Get 2FA QRcode buttons do not work as the JavaScript to determine the action cannot find the buttons. Don't think I broke it but I may have. The way you're doing it feels clunky - what about a per button listener to submit the form? Anyway, I just changed the form submit location manually to test.
