# Authentication & Session Management (Development Notes)

Please read the [authentication usage instructions first](../usage/authentication.md) as that provides some key information for understanding the below brief notes.

IXP Manager uses Laravel's standard authentication framework but with the [Laravel Doctrine ORM](http://www.laraveldoctrine.org/) [authentication](http://www.laraveldoctrine.org/docs/1.4/orm/auth) rather than Eloquent.

See also [Barry O'Donovan's PHP write up of the 2fa and user session management changes introduced in v5.3.0](https://www.barryodonovan.com/2020/02/06/2fa-and-user-session-management-in-ixp-manager) and the [v5.2.0 to v5.3.0 diff](https://github.com/inex/IXP-Manager/compare/v5.2.0...v5.3.0). 

## Mutliple Sessions / Remember Me Cookies

The default Laravel functionality around *remember me* is a single shared token across multiple devices. In practice this never worked well for us (but this is most likely a consequence of using LaravelDoctrine). Regardless, we also wanted to expand the functionality to uniquely identify each session and allow other sessions to be logged out by the user.

### SessionGuard and UserProvider

Most of the functionality exists in the session guard and user provider classes. We have overridden these here:

* `app/Services/Auth/SessionGuard.php`
* `app/Services/Auth/DoctrineUserProvider.php`

Again, the idea is to minimise the changes required to the core Laravel framework (and LaravelDoctrine).


### How It Works

When you log in and check *remember me*, IXP Manager will create a new `UserRememberToken` database entry with a unique token and an expiry set to `config( 'auth.guards.web.expire')` (note this is minutes).

Your browser will be sent a cookie named `remember_web_xxxx` (where `xxxx` is random). This cookie contains the encrypted token that was created (`UserRememberToken`). IXP Manager uses this cookie to create a new authenticated session if your previous session has timed out, etc.

Note that this `remember_web_xxxx` cookie has an indefinite expiry date - the actual expiring of the *remember me* session is handled by the `expiry` field in the `UserRememberToken` database entry.

When you subsequently make a request to IXP Manager:

1. the SessionGuard (see the `user()` method) first tries to retrieve your session via the standard browser session cookie (`laravel_session`).
2. If that does not exist or has expired, it then looks for `remember_web_xxxx` cookie and, if it exists, validates it and looks you in with a new `laravel_session`.


## Two-Factor Authentication

Two-factor authentication (2fa) is implemented using the [pragmarx/google2fa](https://github.com/antonioribeiro/google2fa) package via its Laravel bridge [antonioribeiro/google2fa-laravel](https://github.com/antonioribeiro/google2fa-laravel).

The database table for storing a user's secret key is `user_2fa`. 2FA for a user is enabled if:

1. there exists a `$user->getUser2FA()` entity (one to one); and
2. `$user->getUser2FA()->enabled()` is `true`.

Once 2fa is enabled, the mechanism for enforcing it is the `2fa` middleware. This is applied to all authenticated http web requests via `app/Providers/RouteServiceProvider.php`.

### Avoiding 2fa on Remember Me Sessions

We use the [antonioribeiro/google2fa-laravel](https://github.com/antonioribeiro/google2fa-laravel) bridge's `PragmaRX\Google2FALaravel\Events\LoginSucceeded` event to update a user's remember me token via the listener `IXP\Listeners\Auth\Google2FALoginSucceeded`. The update is to set `user_remember_tokens.is_2fa_complete` to `true` so that the SessionGuard knows to skip 2fa on these sessions.
