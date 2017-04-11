# Upgrade From v3

Due to the significant changes between IXP Manager v3 and v4, there is no in place upgrade process. The advised way to handle this is to install v4 in parallel and then switch over (by adjusting your DNS or Apache configuration for example) to the new v4 directory/server.


This documenation was compiled while performing an upgrade on three separate IXP Manager installations.

**Before you proceed, please check the requirement listed in [the official installation instructions](manually.md).**

## Duplicating the Database

As we're installing in parallel, we want to duplicate the database.

When granting permissions on the new database, use your existing IXP Manager database credentials for ease of configuration.

```sh
mysql -u root -pXXX -e 'CREATE DATABASE ixp4 CHARACTER SET = "utf8mb4" COLLATE = "utf8mb4_unicode_ci";'

mysqldump -u root -pXXX ixp | mysql -u root -pXXX ixp4

mysql -u root -pXXX -e 'GRANT ALL ON ixp4.* TO `ixp`@`localhost` IDENTIFIED BY "YYY";'

# and test:
mysql -u ixp -pYYY -h localhost ixp4
```



## Install IXP Manager

This is very much a tl;dr version of [the official installation instructions](manually.md) which you should review if you need additional help.

The code for IXP Manager is maintained on GitHub and the canonical repository is [inex/IXP-Manager](https://github.com/inex/IXP-Manager).

Log into the server where you wish to install IXP Manager and move to the directory where you wish to install (we use `/srv/ixpmanager` here as an example and which will be referred to as `$IXPROOT` below).

Note that it should not be checked out into any web exposed directory (e.g. do not checkout to `/var/www`).

```sh
IXPROOT=/srv/ixpmanager

# get the source / application
git clone https://github.com/inex/IXP-Manager.git $IXPROOT
cd $IXPROOT

# Using https://getcomposer.org/
composer.phar install

# Using https://bower.io/
bower install

# Start with the example configuration and edit.
# Read the official documentation for help.
# Ensure you configure the database.
# More notes on this follow below.
cp .env.example .env
php artisan key:generate
joe .env

# File system permissions
chown -R www-data: var/ storage/ bootstrap/cache
```



## Initial Configuration Tasks

### New Local Settings / Configuration (Laravel)

IXP Manager v4 uses a new PHP framework (Zend Framework swapped for Laravel). As such, all the older configuration options (from `application/configs/application.ini`) need to be moved to `.env`.

The [php dotenv](https://github.com/vlucas/phpdotenv) file (`.env`) is where all the new configuration options go. These in turn are used by the configuration files under `config/`.

**NB: Where possible, place local changes into `.env` rather than changing the config files as these files are under version control. See [Laravel's documentation on this](http://laravel.com/docs/5.4/installation#configuration) and email the mailing list for help.**



### Update the Database Schema

There's about 50 schema changed between the end of v3 and v4.4.

View the required changes with:

```
./artisan doctrine:schema:update --sql
```

And apply with:

```
./artisan doctrine:schema:update --force
```
 Note that this may take a few minutes if you have a lot of data such as BGP session data.



## MRTG Graphing Migration

We've implemented a new graphing backend called :ref:`features-graphing`. One of the changes is that the graphing directory structure and filenaming conventions have changed. Primarily, we've replaced non-static handles (such as database fields like `customer.shortname` or `physicalinterface.minitorindex` or `switcher.name` with immutable primary keys).

As such, you need to both rename the statistics structure and regenerate the configuration. **It is strongly recommended you copy your existing files and do this in parallel or, at least keep a backup.** Also, stop the MRTG daemon before starting.


### Example

First, you'll need to update your local configuration in `.env` by setting something like:

```
GRAPHER_BACKENDS="mrtg"
GRAPHER_BACKEND_MRTG_LOGDIR="/path/to/mrtg/data"
GRAPHER_BACKEND_MRTG_WORKDIR="/path/to/mrtg/data"
GRAPHER_CACHE_ENABLED=true
```

See the *Grapher* documentation for full details.

You'll then need to migrate all your MRTG files to the new naming scheme:

```sh
# set a variable for what will become the 'old' files for convenience
OLDMRTG=/home/old

# v3 MRTG directory is /home/mrtg. let's move it out of the way
mv /home/mrtg $OLDMRTG

# position ourselves in the IXP Manager root directory
cd /path/to/ixp4

# stop mrtg
service mrtg stop  # or as appropriate for your platform

# migrate IXP graphs
php artisan grapher:backend:mrtg:upgrade mv -L $OLDMRTG -X | sh

# migrate infrastructure graphs
php artisan grapher:backend:mrtg:upgrade mv -L $OLDMRTG -I | sh

# migrate switch graphs
php artisan grapher:backend:mrtg:upgrade mv -L $OLDMRTG -S | sh

# migrate trunk graphs and configuration
php artisan grapher:backend:mrtg:upgrade mv -L $OLDMRTG -T | sh
php artisan grapher:backend:mrtg:upgrade migrate-trunk-config --no-backup

# create member directories
php artisan grapher:backend:mrtg:upgrade mkdir -L $OLDMRTG -M | sh

# migrate member physical interface graphs
php artisan grapher:backend:mrtg:upgrade mv -L $OLDMRTG -P | sh

# migrate member LAG graphs
php artisan grapher:backend:mrtg:upgrade mv -L $OLDMRTG -Q | sh

# migrate member aggregate graphs
php artisan grapher:backend:mrtg:upgrade mv -L $OLDMRTG -C | sh

# regenerate mrtg configuration
php artisan grapher:generate-configuration -B mrtg > path/to/mrtg.conf

# start mrtg
service mrtg start  # or as appropriate for your platform
```
