# Operational Notes

This page will collect various operational notes, hints and tips and FAQs over time.


## Server Topology

**Added 2020-10-28, Nick Hilliard**

On the mailing list, [we were asked about recommended server topologies](https://www.inex.ie/pipermail/ixpmanager/2020-September/002803.html). Nick answered:


At INEX, we split services over different physical machines running virtual servers to keep them as separate as possible.  This means we can perform maintenance on individual components relatively easily without affecting other components. Currently we have the following configured:

1. database VM
2. ixpmanager web front-end VM
3. monitoring VM (mrtg / nagios)
4. sflow VM
5. 2x rpki VMs
6. route collector VM
7. as112 server vm

We run route servers on different physical servers. They're kept separate (different hardware, different hypervisor, not attached to the orchestration system) because they're categorised as critical production servers, i.e. if they go down, production IXP traffic may be affected.

It doesn't really matter what hypervisor software you use.  We've used ESXi, Xencenter and XCP-ng and they all work fine.  Our current preference is for XCP-ng because it provides live migration of VMs on local disk storage without a license (XC and ESXi both need a license for this).

It would be a good idea to use two physically identical servers for the hypervisor, so that you can use services like VM migration and live-migration.  For disk storage, we'd recommend RAID with battery backup, so that you can add or replace physically failed disks easily.

One thing that does matter is disk I/O on the sflow server - if you have anything more than about 30 IXP participants, then you need SSD to handle the iops.


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
