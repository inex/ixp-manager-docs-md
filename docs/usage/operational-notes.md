# Operational Notes

This page will collect various operational notes, hints and tips and FAQs over time.


## Backup IXP Manager

**Added 2020-03-24, Barry O'Donovan**

On the mailing list, someone asked about backing up IXP Manager before an upgrade. Barry O'Donovan [answered this here](https://www.inex.ie/pipermail/ixpmanager/2020-March/002495.html) and the advice was:

> It's not something I generally do as we have our production servers backed up nightly. But:

Assuming you have IXP Manager installed at /srv/ixpmanager then I'd proceed as follows (replacing yyyymmdd with today's date):


1. Put IXP Manager in maintenance mode (`php /srv/ixpmanager/artisan down`).

2. Take a MySQL dump:
    ```
    mysqldump --lock-tables --quick --skip-events --triggers \
        -h <host> -u <username> -p<password> ixpmanager |    \
        bzip2 -9 >/srv/ixpmanager/db-yyyymmdd.sql.bz2
    ```

3. Duplicate the IXP Manager directory in its entirety:
    ```
    rsync -a /srv/ixpmanager/ /srv/ixpmanager-yyyymmdd
    ```

4. Upgrade IXP Manager per the usual instructions.


If you need to rollback then:

1. Restore the database from the dump above:
    ```
    bzcat /srv/ixpmanager/db-yyyymmdd.sql.bz2 | \
        mysql -h <host> -u <username> -p<password> ixpmanager
    ```

2. Shift the directories around:
    ```
    mv /srv/ixpmanager /srv/ixpmanager-failed
    mv /srv/ixpmanager-yyyymmdd /srv/ixpmanager
    ```



## Apache vs Nginx

**Added 2020-04-21, Barry O'Donovan**

A common question is will IXP Manager work with Nginx + php-fpm considering the automated installation script uses Apache. The short answer is: yes, of course! Use whichever you're most comfortable with.

From experience, people who install IXP Manager **and** end up asking for installation help are not overly comfortable with Linux / web servers. The easiest installation and maintainable option (by a measurable distance) is Apache. This is why the installation script uses it.

Do we recommend either / any advantages to one over the other? No and no.  IXP Manager is a low volume / transaction application. Whatever typical performance benefits you might expect from Nginx + php-fpm simply won't apply here.
