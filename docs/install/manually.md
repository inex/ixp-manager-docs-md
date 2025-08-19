# Manual Installation

???+ note "**This page was updated in July 2025 for the release of IXP Manager v7.0 and installation on Ubuntu LTS 24.04.**"

## Video Tutorial

We created a video tutorial demonstrating the manual installation process for IXP Manager v7.0.0 (August 2025) on Ubuntu LTS 24.04. You can find the [latest installation videos](https://www.ixpmanager.org/download/install). As always, [the full catalog of video tutorials is here](https://www.ixpmanager.org/support/tutorials).


## Requirements

IXP Manager tries to stay current in terms of technology. Typically, this means some element of framework refresh(es) every couple of years and other more incremental package upgrades with minor version upgrades. As well as the obvious reasons for this, there is also the requirement to prevent developer apathy - insisting on legacy frameworks and packages that have been EOL'd provides a major stumbling block for bringing on new developers and contributors.

The current requirements for the web application are:

* a Linux / BSD host - **all documentation and videos relate to Ubuntu LTS**.
* MySQL 8.
* Apache / Nginx / etc.
* PHP 8.4. **Note that IXP Manager >= v7.0 will not run on other versions of PHP.**
* Memcached - optional but recommended.

To complete the installation using the included config/scripts, you will also need to have installed git (`apt install git`) and a number of PHP extensions (see the example `apt install` below).

Regrettably the potential combinations of operating systems, versions of same and then versions of PHP are too numerous to provide individual support. As such, we recommend installing IXP Manager on Ubuntu LTS 24.04 and we officially support this platform.

In fact, we provide a complete installation script for this - see [the automated installation page](automated-script.md) for details. If you have any issues with the manual installation, the automated script should be your first reference to compare what you are doing to what we recommend.

For completeness, the IXP Manager installation script for Ubuntu 24.04 LTS installs:

```sh
# start with a fresh update of all installed packages
apt-get update
apt-get dist-upgrade

# ensure basic tools are installed
apt-get install -yq ubuntu-minimal openssl wget net-tools

# We need PHP 8.4 for IXP Manager v7 and we need to get this from
# Ondrej's super PPA:
apt-get install -yq software-properties-common
add-apt-repository -y ppa:ondrej/php

# Install the LAMP stack
apt install -qy apache2 php8.4 php8.4-intl php8.4-rrd php8.4-cgi php8.4-cli \
    php8.4-snmp php8.4-curl  php8.4-memcached libapache2-mod-php8.4 mysql-server         \
    mysql-client php8.4-mysql memcached snmp php8.4-mbstring php8.4-xml php8.4-gd        \
    php8.4-bcmath bgpq3 php8.4-memcache unzip php8.4-zip git php8.4-yaml                 \
    php8.4-ds libconfig-general-perl libnetaddr-ip-perl mrtg  libconfig-general-perl     \
    libnetaddr-ip-perl rrdtool librrds-perl curl  
```

As Ubuntu 24.04 LTS comes with PHP 8.3 installed, we need Ondřej Surý's excellent [Ubuntu PHP PPA](https://launchpad.net/~ondrej/+archive/ubuntu/php). Perhaps consider [buying him a pint](https://deb.sury.org/#donate)). 


### Get the IXP Manager Source

The code for IXP Manager is maintained on GitHub and the canonical repository is [inex/IXP-Manager](https://github.com/inex/IXP-Manager).

Log into the server where you wish to install IXP Manager. Move to the directory where you wish to store the source (the automated script, our documentation and our examples use `/srv/ixpmanager` which we refer to as `$IXPROOT`). Note that it **should not** be cloned into any web exposed directory (e.g. do not clone to `/var/www`).

```sh
IXPROOT=/srv/ixpmanager
cd /srv
git clone https://github.com/inex/IXP-Manager.git ixpmanager
cd $IXPROOT   # /srv/ixpmanager
git checkout release-v7
chown -R www-data: bootstrap/cache storage
```

## Initial Setup and Dependencies


### Dependencies

Install the required PHP libraries:

First you will need Composer v2, PHP's package manager. You can install composer on Ubuntu, but it can become dated quite quickly and installs a bunch of other packages. We recommend that you download and install it per the [copy and paste instructions here](https://getcomposer.org/download/) (always satisfy yourself with the trustworthiness of the source when downloading and executing scripts).

We assume you downloaded it to `$IXPROOT` as `composer.phar`.

Then you can install the dependencies as follows:

```sh
cd $IXPROOT
php composer.phar install --no-dev --prefer-dist
cp .env.example .env
php artisan key:generate
```

## Database Setup


Use whatever means you like to create a database and user for IXP Manager. For example:

```mysql
CREATE DATABASE `ixpmanager` CHARACTER SET = 'utf8mb4' COLLATE = 'utf8mb4_unicode_ci';
CREATE USER `ixpmanager`@`localhost` IDENTIFIED BY '<pick a password!>';
GRANT SUPER ON *.* TO `ixpmanager`@`localhost`;
GRANT ALL ON `ixpmanager`.* TO `ixpmanager`@`localhost`;
FLUSH PRIVILEGES;
```

Then edit `$IXPROOT/.env` and set the database options:

```dotenv
DB_HOST=localhost
DB_DATABASE=ixpmanager
DB_USERNAME=ixpmanager
DB_PASSWORD=<the password you picked above!>
```

Now create the database schema:

```sh
php artisan migrate
```

If you have developed your own scripts that use deprecated views, create them via:

```sh
php artisan update:reset-mysql-views
```

### Configuration

Edit `$IXPROOT/.env` and review and set/change all parameters. Hopefully this is mostly documented and clear, but please start a discussion on the mailing list if you have difficultly and we'll update this and the example file's documentation as appropriate.

From IXP Manager v7, there is also a UI for admins to edit these settings. However, you will have to complete various steps below before you can login.

### Initial Database Objects

Using the settings you edited in `.env` we'll create some database objects.

First, create the password for the initial admin user. The following will create a secure random password and set a bash environment variable so it can be used by the set-up wizard:

```sh
cd $IXPROOT
source .env
IXPM_ADMIN_PW="$( openssl rand -base64 12 )"
echo Your password is: $IXPM_ADMIN_PW
export IXP_SETUP_ADMIN_PASSWORD=$IXPM_ADMIN_PW
```

Then run the following:

```sh
php artisan ixp-manager:setup-wizard --ixp-shortname="<ixp>"   \
  --admin-name="<Your Name>"                                   \
  --admin-username="<Your Desired Username>"                   \
  --admin-email="<Your Email>"                                 \
  --asn="<your IXP's asn>" 
```

where:

* the `--ixp-shortname` is typically some 3-5 letter abbreviation for your IXP.
* the `--admin-xxx` options are for your first admin user, and, if the script is run in the same cli session as the password generation above, this password will be set.
* the asn is your IXP's AS number.
* you can add `--echo-password` to see the password while the script runs.


And finally seed the database:

```sh
cd $IXPROOT
php artisan db:seed --force --class=IRRDBs
php artisan db:seed --force --class=Vendors
php artisan db:seed --force --class=ContactGroups
```

## File Permissions

The web server needs write access to some directories:

```sh
cd $IXPROOT
chown -R www-data: storage/ bootstrap/cache/
chmod -R u+rwX     storage/ bootstrap/cache/
```

## Setting Up Apache


Here is a sample virtual hosts file for IXP Manager (replace `{$IXPROOT}` as appropriate!):

```apache
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot ${IXPROOT}/public
    <Directory ${IXPROOT}/public>
        Options FollowSymLinks
        AllowOverride None
        Require all granted
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} -s [OR]
        RewriteCond %{REQUEST_FILENAME} -l [OR]
        RewriteCond %{REQUEST_FILENAME} -d
        RewriteRule ^.*$ - [NC,L]
        RewriteRule ^.*$ /index.php [NC,L]
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

You also need to enable rewrite:

```sh
a2enmod rewrite
service apache2 restart
```

# Congratulations!


Your new IXP Manager installation should be accessible via your server's IP address using the username (`$USERNAME`) and password (`$IXPM_ADMIN_PW`) you set above.

If you plan to use this in production, you should:

* secure your server with an iptables firewall
* install an SSL certificate and redirect HTTP access to HTTPS
* complete the installation of the many features of IXP Manager such as route server generation, member stats, peer to peer graphs, etc.
* PLEASE TELL US! We'd like to add you to the users list at [https://www.ixpmanager.org/community/world-map](https://www.ixpmanager.org/community/world-map) - just complete the form there or drop us an email to `operations <at> inex <dot> ie`.


**What next? See our [post-install / next steps document here](next-steps.md).**
