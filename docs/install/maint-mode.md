# Maintenance Mode

While most updates of **IXP Manager** are quick, some may be more involved with schema updates or complicated migration steps. In these cases it's useful and advisable to put **IXP Manager** in maintenance mode.

Maintenance mode is now handled by Laravel's built in tool for this. You can review [their own documentation for this](https://laravel.com/docs/5.3/configuration#maintenance-mode) which us copied here.

When your application is in maintenance mode, a custom view will be displayed for all requests into your application. This makes it easy to "disable" your application while it is updating or when you are performing maintenance. A maintenance mode check is included in the default middleware stack for your application. If the application is in maintenance mode, a `MaintenanceModeException` will be thrown with a status code of 503.

To enable maintenance mode, simply execute the down Artisan command:

```
php artisan down
```

You may also provide message and retry options to the down command. The message value may be used to display or log a custom message, while the retry value will be set as the Retry-After HTTP header's value::

```
php artisan down --message='Upgrading Database' --retry=60
```

To disable maintenance mode, use the up command::

```
php artisan up
```
