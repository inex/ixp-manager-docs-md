# Upgrade From v3

To upgrade from IXP Manager v3, you must install v4 in parallel and then switch over by adjusting your Apache configuration to the new v4 directory (or just move v3 out of the way and replace it with v4).

**THESE ARE DRAFT NOTES FROM A TEST UPGRADE. THESE WILL BE FLESHED OUT SOON.**


## Duplicating the Database

As we're installing in parallel, we want to duplicate the database as follows. When granting permissions on the new database, use your existing IXP Manager database credentials for ease of configuration.

```sh
mysql -u root -pXXX -e 'CREATE DATABASE ixp4 CHARACTER SET = "utf8mb4" COLLATE = "utf8mb4_unicode_ci";'
mysqldump -u root -pXXX ixp | mysql -u root -pXXX ixp4
mysql -u root -pXXX -e 'GRANT ALL ON ixp4.* TO `ixp`@`localhost` IDENTIFIED BY "YYY";'
# and test:
mysql -u ixp -pYYY -h localhost ixp4
```

## Get the IXP Manager Source

The code for IXP Manager is maintained on GitHub and the canonical repository is [inex/IXP-Manager](https://github.com/inex/IXP-Manager).

Log into the server where you wish to install IXP Manager. Move to the directory where you wish to store the source. Note that it should not be checked out into any web exposed directory (e.g. do not checkout to `/var/www`). In my case, I'm going to use `/srv/ixp` which will be referred to as `$IXPROOT` below. So I:

```sh
cd /usr/local
git clone https://github.com/inex/IXP-Manager.git ixp4
```

You now need to create the text file `$IXPROOT/.env` containing database details from above:

```dotenv
DB_HOST=localhost
DB_DATABASE=ixp4
DB_USERNAME=ixp
DB_PASSWORD=XXX
```

And then run:

```sh
composer update
bower update
```

## Initial Configuration Tasks

### New Local Settings / Configuration (Laravel)


As v4 is a version in migration from older libraries like Zend Framework to Laravel, we need to do a bit of setup for both frameworks. First Laravel: we'll essentially set defaults in `$IXPROOT/.env` which will be used by files in `$IXPROOT/config`. Feel free to look at those files and add `.env` parameters to suit your own environment.

First, the application key needs to be set and unique. Execute the following command and you should see a similar output (but a different key):

```
php artisan key:generate
Application key [XjWtsiPl_CHANGE_ME_CHANGE_ME] set successfully.
```

Add the APP_KEY to the `.env` file by copying the key above:

```
APP_KEY=XjWtsiPl_CHANGE_ME_CHANGE_ME
```

**NB: Where possible, place local changes into `.env` rather than changing the config files as these files are under version control. See [Laravel's documentation on this](http://laravel.com/docs/5.1/installation#configuration) and email the mailing list for help.**


Here are some hints on what you might want to set:

* `config/app.php`
  *  Set: `APP_URL` in `$IXPROOT/.env`.
* `config/cache.php`
  * Either leave `CACHE_DRIVER` as `file` or set otherwise in `$IXPROOT/.env`.
* `config/identity.php`
  * Copy `config/identity.php.dist` to `config/identity.php` and edit for your IXP *(essentially copy from your v3 application/configs/application.ini)*.
* `config/mail.php`
  * Set appropriate options for mail relay. Specifically `MAIL_DRIVER`, `MAIL_HOST` and `MAIL_PORT`.

### Migrate Old Zend Framework Settings


Copy your IXP v3 `application/configs/application.ini` file to your new v4 `application/configs` and edit as follows:

1. Change the database name:

    ```
    -resources.doctrine2.connection.options.dbname   = 'ixp'
    +resources.doctrine2.connection.options.dbname   = 'ixp4'
    ```

2. Change paths as follows:

    ```
    -includePaths.osssnmp    = APPLICATION_PATH "/../library/OSS_SNMP.git"
    -includePaths.osslibrary = APPLICATION_PATH "/../library/OSS-Framework.git"
    +includePaths.osslibrary = APPLICATION_PATH "/../vendor/opensolutions/oss-framework/src/"

    -pluginPaths.OSS_Resource = APPLICATION_PATH "/../library/OSS-Framework.git/OSS/Resource"
    +pluginPaths.OSS_Resource = APPLICATION_PATH "/../vendor/opensolutions/oss-framework/src/OSS/Resource"

    -resources.smarty.plugins[] = APPLICATION_PATH "/../library/OSS-Framework.git/OSS/Smarty/functions"
    -resources.smarty.plugins[] = APPLICATION_PATH "/../library/Smarty/plugins"
    -resources.smarty.plugins[] = APPLICATION_PATH "/../library/Smarty/sysplugins"
    +resources.smarty.plugins[] = APPLICATION_PATH "/../vendor/opensolutions/oss-framework/src/OSS/Smarty/functions"
    +resources.smarty.plugins[] = APPLICATION_PATH "/../vendor/smarty/smarty/libs/plugins"
    +resources.smarty.plugins[] = APPLICATION_PATH "/../vendor/smarty/smarty/libs/sysplugins"
    ```

3. Change Doctrine2 options as follows:

    ```
    -resources.doctrine2cache.path               = "/usr/share/php/Doctrine/ORM"
    -resources.doctrine2cache.autoload_method    = "pear"
    +resources.doctrine2cache.autoload_method    = "composer"
    +resources.doctrine2cache.namespace          = 'ixp4'

    -resources.doctrine2.models_path        = APPLICATION_PATH
    -resources.doctrine2.proxies_path       = APPLICATION_PATH "/Proxies"
    -resources.doctrine2.repositories_path  = APPLICATION_PATH
    -resources.doctrine2.xml_schema_path    = APPLICATION_PATH "/../doctrine/schema"
    +resources.doctrine2.models_path        = APPLICATION_PATH "/../database"
    +resources.doctrine2.proxies_path       = APPLICATION_PATH "/../database/Proxies"
    +resources.doctrine2.repositories_path  = APPLICATION_PATH "/../database"
    +resources.doctrine2.xml_schema_path    = APPLICATION_PATH "/../database/xml"
    ```

### Update the Database Schema


View the required changes with:

```
./artisan doctrine:schema:update --sql
```

And apply with:

```
./artisan doctrine:schema:update --force
```


## Apache


```
Alias /ixp4 /srv/ixp4/public
<Directory /srv/ixp4/public>
    Options FollowSymLinks
    AllowOverride None
    Require all granted

    SetEnv APPLICATION_ENV production

    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} -s [OR]
    RewriteCond %{REQUEST_FILENAME} -l [OR]
    RewriteCond %{REQUEST_FILENAME} -d
    RewriteRule ^.*$ - [NC,L]
    RewriteRule ^.*$ /ixp4/index.php [NC,L]
</Directory>
```

## File System Permissions

```
chown -R www-data: var/ storage/ bootstrap/cache
```


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
