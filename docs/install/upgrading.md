# Upgrading IXP Manager

> These upgrade instructions relate to upgrading when you are already using IXP Manager v4.x.

The upgrade process for IXP Manager is currently a manual task. Especially database schema updates.

The release notes for each version may contain specific upgrade instructions including schema changes.

In the below, we assume the following installation directory - alter this to suit your own situation:

```
IXPROOT=/srv/ixpmanager
```


The general process is:

* (1) Enable maintenance mode:

```
cd $IXPROOT
./artisan down
```

* (2) Using Git, checkout the next version up from yours. For IXP Manager v4, this essentially means pulling from `master`.

```
# move to the directory where you have installed IXP Manager
cd $IXPROOT
# you should be in the master branch (if not: git checkout master)
# pull the latest code
git pull
```

* (3) Install latest required libraries from composer:

```
composer install
```

* (4) Install latest frontend dependencies:

```
# if asked to chose a jquery version, chose the latest / highest version offered
bower install
```

* (5) Restart Memcached. Do not forget / skip this step!

* (6) Update the database schema:

```
# review / sanity check first:
./artisan doctrine:schema:update --sql
# If in doubt, take a mysqldump of your database first.
# migrate:
./artisan doctrine:schema:update --force
```

* (7) Restart Memcached (yes, again). Do not forget / skip this step!

* (8) Disable maintenance mode:

```
./artisan up
```

## Correcting Database Issues / Verifying Your Schema

Because of the manual process of database updates, it is possible your database schema may fall out of sync.

If you are having issues, first and foremost, restart Memcached. Doctrine2 caches entities and schema information in Memcached so, after an upgrade, you must restart Memcached.

You can verify and update your schema using the `artisan` script. The first action should be validation - here is a working example with no database issues:

```
./artisan doctrine:schema:validate

Validating for default entity manager...
[Mapping]  OK - The mapping files are correct.
[Database] OK - The database schema is in sync with the mapping files.
```

If there are issues, you can use the following to show what SQL commands are required to bring your schema into line:

```
./artisan doctrine:schema:update --sql
```

And you can let Doctrine make the changes for you via:

```
./artisan doctrine:schema:update --force
```

Doctrine2 maintains the entities, proxies and repository classes. Ideally you should never need to do the following on a production installation - as we maintain these files with Git - but if you're developing / testing IXP Manager, you may need to.

The process for updating these files with schema changes / updates is:

```
cd $IXPROOT
/etc/init.d/memcached restart    # (or as appropriate for your system)
./artisan doctrine:generate:entities database
./artisan doctrine:generate:proxies
```
