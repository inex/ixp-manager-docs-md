# Maintenance Mode

While most updates of **IXP Manager** are quick, some may be more involved with schema updates or complicated migration steps. In these cases it's useful and advisable to put **IXP Manager** in maintenance mode.

Maintenance mode is now handled by Laravel's built in tool for this. You can review [their own documentation for this](https://laravel.com/docs/12.x/configuration#maintenance-mode) for a complete description of the feature.

A maintenance mode check is included in the default middleware stack for your application. If the application is in maintenance mode, a `MaintenanceModeException` will be thrown with a status code of 503. This message simply states `Service Unavailable`.

To enable maintenance mode, simply execute the down Artisan command:

```
php artisan down
```

You may instead choose to display a more complete maintenance mode page. You can use [skinning](skinning.md) to customize or completely replace the included page. If set, the retry value will be set as the Retry-After HTTP header's value::

```
php artisan down --render=errors::maintenance --retry=60
```

To disable maintenance mode, use the up command::

```
php artisan up
```
