# Cron Jobs - Task Scheduling

Prior to IXP Manager v5, a number of cron jobs had to be configured manually. From v5.0 onwards, cron jobs are handled by [Laravel's task scheduler](https://laravel.com/docs/5.8/scheduling). As such, you just need a single cron job entry such as:

```
* * * * *    www-data    cd /path-to-your-ixp-manager && php artisan schedule:run >> /dev/null 2>&1
```

**FIXME** Add to installation script

**FIXME** Instructions to disable scheduled tasks.
