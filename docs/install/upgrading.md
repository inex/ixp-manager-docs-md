# Upgrading IXP Manager - v6.x

???+ note "**These upgrade instructions relate to upgrading when you are already using IXP Manager v6.x.**"

    * For instructions on how to upgrade from v5.8.0 to v6.0.0, please see [the release notes for v6](https://github.com/inex/IXP-Manager/releases/tag/v6.0.0).

    * For instructions on how to upgrade within the v5.x releases, please [see this page](upgrade-v5.md).

    * For instructions on how to upgrade within the v4.x releases, please [see this page](upgrade-v4.md).

    * For instructions on how to upgrade from v3.x to v4, please [see this page](upgrade-v3.md).

    * For instructions on how to upgrade from v4.9.x to v5.0, please see [the v5.0 release notes](https://github.com/inex/IXP-Manager/releases/tag/v5.0.0).



### Video Tutorial

We created a video tutorial demonstrating the upgrade process for IXP Manager within the v5.x branch which is not dissimilar to this. You can find the [video here](https://www.youtube.com/watch?v=FqsWCudPUak) in our [YouTube channel](https://www.youtube.com/channel/UCeW2fmMTBtE4fnlmg-2-evA). We also have a video on upgrading a legacy version (v4.9.3 to v5.7.0) - see [the video here](https://youtu.be/CXTjgRUESAc) and [some further details in this blog post](https://www.barryodonovan.com/2020/09/08/upgrading-legacy-versions-of-ixp-manager). As always, [the full catalog of video tutorials is here](https://www.ixpmanager.org/support/tutorials).


## Instructions

We track [releases on GitHub](https://github.com/inex/IXP-Manager/releases).

You will find standard instructions for upgrading IXP Manager below. Note that the release notes for each version may contain specific upgrade instructions including schema changes.

If you have missed some versions, the most sensible approach is to upgrade to each minor release in sequence (6.0.0 -> 6.1.0 -> 6.2.0 -> ...) and then to the latest patch version in the latest minor version.

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

3. Using Git, checkout the next minor / latest patch version up from yours. For IXP Manager v6:

    ```sh
    cd $IXPROOT
    # pull the latest code
    git fetch --all
    # check out the version you are upgrading to
    git checkout v6.x.y
    ```


4. Install latest required libraries from composer [**(see notes below)**](#updating-composer-dependancies). Note that composer may be in different locations.

    ```sh
    # This assumes composer is installed globally.
    # (Typical for IXP Manager on Ubtuntu 20.04):
    sudo -u $MY_WWW_USER bash -c "HOME=${IXPROOT}/storage && cd ${IXPROOT} \
        && composer install --no-dev --prefer-dist"

    ```

5. Restart Memcached and clear the cache.

    ```sh
    systemctl restart memcached.service
    php $IXPROOT/artisan cache:clear
    ```

6. Update the database schema:

    ```sh
    # (you really should take a mysqldump of your database first)

    # (optional) see what changes will be made:
    php $IXPROOT/artisan migrate:status

    # migrate:
    php $IXPROOT/artisan migrate
    ```

7. Ensure there are no version specific changes required in the release notes.

8. Ensure file permissions are still correct.

    ```sh
    chown -R $MY_WWW_USER: ${IXPROOT}/{bootstrap/cache,composer.lock,storage,vendor}
    chmod -R ug+rwX ${IXPROOT}/{bootstrap/cache,composer.lock,storage,vendor}
    ```

10. Clear out all caches:

    ```sh
    php ${IXPROOT}/artisan cache:clear
    php ${IXPROOT}/artisan config:clear
    php ${IXPROOT}/artisan route:clear
    php ${IXPROOT}/artisan view:clear
    ```

11. Disable maintenance mode:

    ```sh
    php ${IXPROOT}/artisan up
    ```

12. Recreate SQL views

    Some older scripts, including the sflow modules, rely on MySQL view tables that may be affected by SQL updates.

    ```sh
    cd ${IXPROOT}
    source .env
    mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_DATABASE < $IXPROOT/tools/sql/views.sql
    ```




## Updating Composer Dependencies

It is not advisable to run composer as root but how you run it will depend on your own installation. The following options would work on Ubuntu (run these as root and the composer commands themselves will be run as `$MY_WWW_USER`). Note that we assume here what you have installed Composer (see: https://getcomposer.org/ ) in the `${IXPROOT}` directory as `composer.phar`.

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
