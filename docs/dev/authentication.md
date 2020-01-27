# Authentication & Session Management (Development Notes)

Please read the [authentication usage instructions first](../usage/authentication.md).

IXP Manager uses Laravel's standard authentication framework but with the [Laravel Doctrine ORM](http://www.laraveldoctrine.org/) [authentication](http://www.laraveldoctrine.org/docs/1.4/orm/auth) rather than Eloquent.


## Two-Factor Authentication

Two-factor authentication (2fa) is implemented using the [pragmarx/google2fa](https://github.com/antonioribeiro/google2fa) package via its Laravel bridge [antonioribeiro/google2fa-laravel](https://github.com/antonioribeiro/google2fa-laravel).

The database table for storing a user's secret key is `user_2fa`. 2FA for a user is enabled if:

1. there exists a `$user->getUser2FA()`` entity (one to one); and
2. `$user->getUser2FA()->enabled()` is `true`.

Once 2fa is enabled, the mechanism for enforcing it is the `2fa` middleware. This is applied to all authenticated http web requests via `app/Providers/RouteServiceProvider.php`.
