# Authentication & Session Management (Development Notes)

Please read the [authentication usage instructions first](../usage/authentication.md).

IXP Manager uses Laravel's standard authentication framework but with the [Laravel Doctrine ORM](http://www.laraveldoctrine.org/) [authentication](http://www.laraveldoctrine.org/docs/1.4/orm/auth) rather than Eloquent.


## Two-Factor Authentication

Two-factor authentication (2fa) is implemented using the [pragmarx/google2fa](https://github.com/antonioribeiro/google2fa) package via its Laravel bridge [antonioribeiro/google2fa-laravel](https://github.com/antonioribeiro/google2fa-laravel).
