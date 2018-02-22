# Upgrading IXP Manager

> These upgrade instructions relate to upgrading when you are already using IXP Manager v4.x.

We track [releases on GitHub](https://github.com/inex/IXP-Manager/releases).

You will find standard instructions for upgrading IXP Manager below. Note that the release notes for each version may contain specific upgrade instructions including schema changes.

If you have missed some versions, the most sensible approach is to upgrade to each minor release in sequence (4.5.0 -> 4.6.0 -> 4.7.0 -> ...) and then to the latest patch version in the latest minor version.

In the below, we assume the following installation directory - alter this to suit your own situation:

```
IXPROOT=/srv/ixpmanager
```


The general process is:

1. Enable maintenance mode:

    ```sh
    cd $IXPROOT
    ./artisan down
    ```

2. Using Git, checkout the next minor / latest patch version up from yours. For IXP Manager v4.

    ```sh
    # move to the directory where you have installed IXP Manager
    cd $IXPROOT
    # pull the latest code
    git fetch
    # check out the version you are upgrading to
    git checkout v4.x.y
    ```

3. Install latest required libraries from composer [**(see notes below)**](#updating-composer-dependancies):

    ```sh
    # this assumes composer.phar is in the IXP Manager install directory. YMMV - see notes below.
    php ./composer.phar install
    ```

4. Install latest frontend dependencies [**(see notes below)**](#updating-bower-dependancies):

    ```sh
    # if asked to chose a jquery version, chose the latest / highest version offered
    bower prune
    bower install
    ```

5. Restart Memcached and clear the cache. Do not forget / skip this step!

    ```sh
    systemctl restart memcached.service
    ./artisan cache:clear
    ```

6. Update the database schema:

    ```sh
    # review / sanity check first:
    ./artisan doctrine:schema:update --sql
    # If in doubt, take a mysqldump of your database first.
    # migrate:
    ./artisan doctrine:schema:update --force
    ```

7. Restart Memcached (yes, again). Do not forget / skip this step!

    ```sh
    systemctl restart memcached.service
    ```

8. Ensure there are no version specific changes required in the release notes.

9. Ensure file permissions are correct.

    ```sh
    MY_WWW_USER=www-data  # fix as appropriate to your operating system
    chown -R $MY_WWW_USER: bootstrap/cache var storage
    chmod -R u+rwX bootstrap/cache var storage
    ```

10. Disable maintenance mode:

    ```sh
    ./artisan up
    ```

## Updating Bower Dependancies

It is not advisable to run bower are root but how you run it will depend on your own installation. The following options would work on Ubuntu (run these as root and the bower commands themselves will be run as `$MY_WWW_USER`):

```sh
# set this to your IXP Manager installation directory
IXPROOT=/srv/ixpmanager

MY_WWW_USER=www-data  # fix as appropriate to your operating system

# ensure www-data can write to bower:
chown -R $MY_WWW_USER: $IXPROOT/public/bower_components ${IXPROOT}/bower.json ${IXPROOT}/storage
chmod -R u+rwX $IXPROOT/public/bower_components ${IXPROOT}/bower.json ${IXPROOT}/storage

# update bower
sudo -u $MY_WWW_USER bash -c "HOME=${IXPROOT}/storage && cd ${IXPROOT} && bower --config.interactive=false -f update"
```

The above command is structured as it is because typically the `www-data` user has a `nologin` shell specified.


## Updating Composer Dependancies

This is similar to the bower section above so please read that if you have not already.

Note that we assume here what you have installed Composer (see: https://getcomposer.org/ ) in the `${IXPROOT}` directory as `composer.phar`. This is where and how the IXP Manager installation scripts and documentation instructions install it.

The following options would work on Ubuntu (run these as root and the composer commands themselves will be run as `$MY_WWW_USER`):

```sh
# set this to your IXP Manager installation directory
IXPROOT=/srv/ixpmanager

MY_WWW_USER=www-data  # fix as appropriate to your operating system

# ensure www-data can write to vendor:
chown -R $MY_WWW_USER: $IXPROOT/vendor ${IXPROOT}/storage
chmod -R u+rwX $IXPROOT/vendor ${IXPROOT}/storage

# update composer
sudo -u $MY_WWW_USER bash -c "HOME=${IXPROOT}/storage && cd ${IXPROOT} && php ./composer.phar install"
```

NB: If composer is not managed by your package management system, you should keep it up to date via the following (using the same definitions from the composer update example above):

```sh
chown -R $MY_WWW_USER: ${IXPROOT}/composer.phar
chmod -R u+rwx ${IXPROOT}/composer.phar
sudo -u $MY_WWW_USER bash -c "HOME=${IXPROOT}/storage && cd ${IXPROOT} && php ./composer.phar selfupdate"
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

Some older scripts also rely on MySQL view tables that may be missing. You can safely run this to (re)create them:

```sh
mysql -u ixp -p ixp < $IXPROOT/tools/sql/views.sql
```
