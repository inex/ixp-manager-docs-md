# Upgrading IXP Manager - v5.x

???+ note "**These upgrade instructions relate to upgrading within the v5.x releases when you are already using IXP Manager v5.x.**"


### Video Tutorial

We created a video tutorial demonstrating the upgrade process for IXP Manager. You can find the [video here](https://www.youtube.com/watch?v=FqsWCudPUak) in our [YouTube channel](https://www.youtube.com/channel/UCeW2fmMTBtE4fnlmg-2-evA). We also have a video on upgrading a legacy version (v4.9.3 to v5.7.0) - see [the video here](https://youtu.be/CXTjgRUESAc) and [some further details in this blog post](https://www.barryodonovan.com/2020/09/08/upgrading-legacy-versions-of-ixp-manager). As always, [the full catalog of video tutorials is here](https://www.ixpmanager.org/support/tutorials).


## Instructions

We track [releases on GitHub](https://github.com/inex/IXP-Manager/releases).

You will find standard instructions for upgrading IXP Manager below. Note that the release notes for each version may contain specific upgrade instructions including schema changes.

If you have missed some versions, the most sensible approach is to upgrade to each minor release in sequence (5.0.0 -> 5.1.0 -> 5.2.0 -> ...) and then to the latest patch version in the latest minor version.

In the below, we assume the following installation directory - alter this to suit your own situation:

```
IXPROOT=/srv/ixpmanager
```

Before you start, **consider if you need to make a backup**. We would expect that most IXP's would have a nightly backup of all their servers at a minimum. If not, or for belt-and-braces, you may want to make a local temporary backup. See [our operational notes on backups](../usage/operational-notes.md#backup-ixp-manager) for an idea on how to do this.



The general process is:

1. Set up some variables and ensure directory permissions are okay:

    ```sh
    # set this to your IXP Manager installation directory
    IXPROOT=/srv/ixpmanager

    # fix as appropriate to your operating system
    MY_WWW_USER=www-data

    # ensure the web server daemon user can write to necessary directories:
    chown -R $MY_WWW_USER: ${IXPROOT}/{bootstrap/cache,composer.lock,storage,vendor}
    chmod -R ug+rwX ${IXPROOT}/{bootstrap/cache,composer.lock,storage,vendor}
    ```

2. Enable maintenance mode:

    ```sh
    php $IXPROOT/artisan down --message='Please wait, currently upgrading...'
    ```

3. Using Git, checkout the next minor / latest patch version up from yours. For IXP Manager v4.

    ```sh
    cd $IXPROOT
    # pull the latest code
    git fetch --all
    # check out the version you are upgrading to
    git checkout v5.x.y
    ```

4. Install latest required libraries from composer [**(see notes below)**](#updating-composer-dependencies). Note that composer may be in different locations.

    ```sh
    # This assumes composer is in the IXP Manager install directory.
    # (Typical for IXP Manager on Ubtuntu 18.04):
    sudo -u $MY_WWW_USER bash -c "HOME=${IXPROOT}/storage && cd ${IXPROOT} \
        && php ./composer.phar install --no-dev --prefer-dist"

    # OR:

    # This assumes composer is installed globally.
    # (Typical for IXP Manager on Ubtuntu 20.04):
    sudo -u $MY_WWW_USER bash -c "HOME=${IXPROOT}/storage && cd ${IXPROOT} \
        && composer install --no-dev --prefer-dist"

    ```

5. Restart Memcached and clear the cache. Do not forget / skip this step!

    ```sh
    systemctl restart memcached.service
    php $IXPROOT/artisan cache:clear
    ```

6. Update the database schema:

    ```sh
    # (you really should take a mysqldump of your database first)

    # (optional) see what changes will be made:
    php $IXPROOT/artisan doctrine:schema:update --sql
    php $IXPROOT/artisan migrate:status

    # migrate:
    php $IXPROOT/artisan doctrine:schema:update --force
    php $IXPROOT/artisan migrate
    ```

7. Restart Memcached (yes, again). Do not forget / skip this step!

    ```sh
    systemctl restart memcached.service
    ```

8. Ensure there are no version specific changes required in the release notes.

9. Ensure file permissions are still correct.

    ```sh
    chown -R $MY_WWW_USER: ${IXPROOT}/{bootstrap/cache,composer.lock,storage,vendor}
    chmod -R ug+rwX ${IXPROOT}/{bootstrap/cache,composer.lock,storage,vendor}
    ```

10. Clear out all caches:

    ```sh
    php ${IXPROOT}/artisan cache:clear
    php ${IXPROOT}/artisan config:clear
    php ${IXPROOT}/artisan doctrine:clear:metadata:cache
    php ${IXPROOT}/artisan doctrine:clear:query:cache
    php ${IXPROOT}/artisan doctrine:clear:result:cache
    php ${IXPROOT}/artisan route:clear
    php ${IXPROOT}/artisan view:clear
    ```

11. Disable maintenance mode:

    ```sh
    php ${IXPROOT}/artisan up
    ```

12. Recreate SQL views

    Some older scripts, including the sflow modules, rely on MySQL view tables that may be affected by SQL updates. You can safely run this to recreate them on versions > v5.5.0:

    ```sh
    php ${IXPROOT}/artisan update:reset-mysql-views
    ```

    If you are running <= v5.4.0 then do this as follows using the appropriate MySQL username and password:

    ```sh
    mysql -u ixp -p ixp < $IXPROOT/tools/sql/views.sql
    ```




## Updating Composer Dependencies

It is not advisable to run composer as root but how you run it will depend on your own installation. The following options would work on Ubuntu (run these as root and the composer commands themselves will be run as `$MY_WWW_USER`). Note that we assume here what you have installed Composer (see: https://getcomposer.org/ ) in the `${IXPROOT}` directory as `composer.phar`. This is where and how the IXP Manager installation scripts and documentation instructions install it.

```sh
# set this to your IXP Manager installation directory
IXPROOT=/srv/ixpmanager

MY_WWW_USER=www-data  # fix as appropriate to your operating system

# ensure the web server daemon user can write to necessary directories:
chown -R $MY_WWW_USER: ${IXPROOT}/{bootstrap/cache,composer.lock,storage,vendor}
chmod -R ug+rwX ${IXPROOT}/{bootstrap/cache,composer.lock,storage,vendor}

# update composer packages
sudo -u $MY_WWW_USER bash -c "HOME=${IXPROOT}/storage && cd ${IXPROOT} \
    && php ./composer.phar install --prefer-dist --no-dev"
```

NB: If composer is not managed by your package management system, you should keep it up to date via the following (using the same definitions from the composer update example above):

```sh
chown -R $MY_WWW_USER: ${IXPROOT}/composer.phar
chmod -R u+rwx ${IXPROOT}/composer.phar
sudo -u $MY_WWW_USER bash -c "HOME=${IXPROOT}/storage && cd ${IXPROOT} && php ./composer.phar selfupdate"
```



## Correcting Database Issues / Verifying Your Schema

Because of the manual process of database updates, it is possible your database schema may fall out of sync.

If you are having issues, first and foremost, restart Memcached / clear your cache (see upgrade instructions above). Doctrine2 caches entities and schema information in Memcached so, after an upgrade, you must restart Memcached.

You can verify and update your schema using the `artisan` script. The first action should be validation - here is a working example with no database issues:

```sh
cd $IXPROOT
./artisan doctrine:schema:validate

Validating for default entity manager...
[Mapping]  OK - The mapping files are correct.
[Database] OK - The database schema is in sync with the mapping files.
```

If there are issues, you can use the following to show what SQL commands are required to bring your schema into line:

```sh
./artisan doctrine:schema:update --sql
```

And you can let Doctrine make the changes for you via:

```sh
./artisan doctrine:schema:update --force
```

Doctrine2 maintains the entities, proxies and repository classes. Ideally you should never need to do the following on a production installation - as we maintain these files with Git - but if you're developing / testing IXP Manager, you may need to.

The process for updating these files with schema changes / updates is:

```sh
cd $IXPROOT
systemctl restart memcached.service           # (or as appropriate for your system)
./artisan doctrine:generate:entities database
./artisan doctrine:generate:proxies
```
