# Cron Jobs - Task Scheduling

Cron jobs / task scheduling is handled by [Laravel's task scheduler](https://laravel.com/docs/11.x/scheduling). As such, you just need a single cron job entry such as:

```
* * * * *    www-data    cd /path-to-your-ixp-manager && php artisan schedule:run >> /dev/null 2>&1
```

You can see the [full schedule in code here](https://github.com/inex/IXP-Manager/blob/master/app/Console/Kernel.php) (look for the function `protected function schedule(Schedule $schedule)`).

## Tasks Referenced Elsewhere

The following tasks are run via this mechanism and are referenced elsewhere in the documentation:

* Uploading MRTG traffic data to the database - documented [in the Grapher MRTG backend page](../grapher/mrtg.md#inserting-traffic-data-into-the-database-reporting-emails) - and runs nightly at 02:00. **NB:** there are email reports that can be added to cron that are not part of the scheduler - see the same page for details on this.
* IRRDB prefix and ASN database for generating route server filters - this is all documented [on the IRRDB page](irrdb.md). **NB:** the scheduler will not run unless you have configured the location of BGPQ3 as per the instructions. This runs every 6 hours.
* [Telescope](../dev/telescope.md) is a debugging / error tracking tool within IXP Manager. In production, it is limited to recording exceptions and other errors. It puts data into a database table of which anything over three days is expunged via the Artisan command `telescope:prune` daily.
* The [OUI database](layer2-addresses.md#oui-database) is updated weekly (Mondays at 09:15).
* Polling / updating switch and switch port details ([see documentation here](../usage/switches.md#automated-polling-snmp-updates)) happens every five minutes.
* Update the record of which customers have / have not [PeeringDB records](peeringdb.md#existence-of-peeringdb-records).
* Update the record of which customers are / are not [participating in MANRS](manrs.md).

## Other Tasks

### Expunging Logs

Some data should not be retained indefinitely for user privacy / GDPR / housekeeping reasons. The `utils:expunge-logs` command runs daily at 03:04 and currently:

1. removes user login history older than 6 months;
2. removes user API keys that expired >3 months ago;
3. removes expired user remember tokens.
