# Authentication & Session Management (Development Notes)

Please read the [authentication usage instructions first](../usage/authentication.md).

IXP Manager uses Laravel's standard authentication framework but with the [Laravel Doctrine ORM](http://www.laraveldoctrine.org/) [authentication](http://www.laraveldoctrine.org/docs/1.4/orm/auth) rather than Eloquent.


## Two-Factor Authentication

Two-factor authentication (2fa) is implemented using the [pragmarx/google2fa](https://github.com/antonioribeiro/google2fa) package via its Laravel bridge [antonioribeiro/google2fa-laravel](https://github.com/antonioribeiro/google2fa-laravel).

The database table for storing a user's secret key is `user_2fa`. 2FA for a user is enabled if:

1. there exists a `$user->getUser2FA()`` entity (one to one); and
2. `$user->getUser2FA()->enabled()` is `true`.

Once 2fa is enabled, the mechanism for enforcing it is the `2fa` middleware. This is applied to all authenticated http web requests via `app/Providers/RouteServiceProvider.php`.


## Mutliple Sessions / Remember Me Cookies

The default Laravel fucntionality around *remember me* is a single shared token across multiple devices. In practice this never worked well for us (but this is most likely a consequence of using LaravelDoctrine or some other change). Regardless, we also wanted to expand the functionality to uniquely identify each session and allow other sessions to be logged out,

### SessionGuard and UserProvider

Most of the functionality exists in the session guard and user provider classes. We have overridden these here:

* s

Again, the idea is to minimise the changes required to the core Laravel framework (and LaravelDoctrine).

### How It Works

When you log in and check *remember me*, IXP Manager will create a new `UserRememberToken` database entry with a unique token and an expiry set to `config( 'auth.guards.web.expire')` (note this is minutes).

Your browser will be sent a cookie named `remember_web_xxxx` (where `xxxx` is random). This cookie contains the encrypted token that was created (`UserRememberToken`). IXP Manager uses this cookie to create a new authenticated session if your previous session has timed out, etc.

Note that this `remember_web_xxxx` cookie has an indefinite expiry date - the actual expiring of the *remember me* session is handled by the `expiry` field in the `UserRememberToken` database entry.
