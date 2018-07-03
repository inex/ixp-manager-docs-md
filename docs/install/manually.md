
# Requirements

IXP Manager tries to stay current in terms of technology. Typically, this means some element of framework refresh(es) every couple of years and other more incremental package upgrades with minor version upgrades. As well as the obvious reasons for this, there is also the requirement to prevent developer apathy - insisting on legacy frameworks and packages that have been EOL'd provides a major stumbling block for bringing on new developers and contributors.

The current requirements for the web application are:

* a Linux / BSD host.
* MySQL version 5.7 or later.
* Apache / Nginx / etc.
* PHP >= 7.0. **Note that IXP Manager will not run on older versions of PHP.**
* Memcached - optional but highly recommended.

To complete the installation using the included config/scripts, you will also need to have installed git (`apt-get install git`) and a number of PHP extensions (see the example `apt-get install` below).

Regrettably the potential combinations of operating systems, versions of
same and then versions of PHP are too numerous to provide individual
support. As such, we recommend installing IXP Manager on Ubuntu LTS 16.04 and we officially support this platform.

In fact we provide a complete installation script for this - see [the automated installation page](automated-script.md) for details. If you have any issues with the manual installation, the automated script should be your first reference to compare what you are doing to what we recommend.

For completeness, the IXP Manager installation script for Ubuntu 16.04 LTS installs:

```sh
apt-get install -qy apache2 php7.0 php7.0-intl php-rrd php7.0-cgi php7.0-cli       \
    php7.0-snmp php7.0-curl php7.0-mcrypt php-memcached libapache2-mod-php7.0      \
    mysql-server mysql-client php7.0-mysql memcached snmp nodejs nodejs-legacy npm \
    php7.0-mbstring php7.0-xml php7.0-gd php7.0-bcmath php-gettext bgpq3           \
    php-memcache unzip php7.0-zip git php-yaml php-ds libconfig-general-perl       \
    libnetaddr-ip-perl mrtg  libconfig-general-perl libnetaddr-ip-perl rrdtool     \
    librrds-perl
```

If you are using a different platform, you will need to replicate the above as appropriate for your chosen platform.


# Get the IXP Manager Source


The code for IXP Manager is maintained on GitHub and the canonical repository is [inex/IXP-Manager](https://github.com/inex/IXP-Manager).

Log into the server where you wish to install IXP Manager. Move to the directory where you wish to store the source (our examples use `/srv/ixpmanager` which we refer to as `$IXPROOT`). Note that it **should not** be checked out into any web exposed directory (e.g. do not checkout to `/var/www`).

```sh
IXPROOT=/srv/ixpmanager
cd /srv
git clone https://github.com/inex/IXP-Manager.git ixpmanager
cd $IXPROOT   # /srv/ixpmanager
git checkout master
chown -R www-data: $IXPROOT
```


# Install Composer and Bower


IXP Manager uses [Composer](http://getcomposer.org/) to manage its PHP dependencies. First, download a copy of the composer.phar. Once you have the PHAR archive, you can either keep it in your local project directory or move to `/usr/local/bin` to use it globally on your system.


The installation script for Ubuntu 16.04 LTS installs these via:

```sh
cd $IXPROOT
EXPECTED_SIGNATURE=$(wget https://composer.github.io/installer.sig -O - -q)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" = "$ACTUAL_SIGNATURE" ]; then
    sudo -u www-data bash -c "HOME=$IXPROOT && cd $IXPROOT && php composer-setup.php --quiet"
    rm $IXPROOT/composer-setup.php
else
    echo -e "\n\nERROR: Invalid installer signature for composer installation"
    rm $IXPROOT/composer-setup.php
    exit 1
fi
```

and:

```sh
npm install -g bower
```


# Initial Setup and Dependancies


## Dependencies

Install the required PHP libraries and frontend CSS/JS packages:

```sh
cd $IXPROOT
php composer.phar install --no-dev --prefer-dist
bower install
cp .env.example .env
php artisan key:generate
```

# Database Setup


Use whatever means you like to create a database and user for IXP Manager. For example:

```mysql
CREATE DATABASE `ixp` CHARACTER SET = 'utf8mb4' COLLATE = 'utf8mb4_unicode_ci';
GRANT ALL ON `ixp`.* TO `ixp`@`localhost` IDENTIFIED BY '<pick a password!>';
FLUSH PRIVILEGES;
```

Then edit `$IXPROOT/.env` and set the database options:

```dotenv
DB_HOST=localhost
DB_DATABASE=ixp
DB_USERNAME=ixp
DB_PASSWORD=password
```

Now create the database schema:

```sh
php artisan doctrine:schema:create
```

Some older scripts still rely on MySQL view tables. Create these with:

```sh
mysql -u ixp -p ixp < $IXPROOT/tools/sql/views.sql
```

### Configuration


Edit `$IXPROOT/.env` and review and set/change all parameters. Hopefully this is mostly documented or clear but please start a discussion on the mailing list if you have difficultly and we'll update this and the example file's documentation as appropriate.

### Initial Database Objects


Using the settings you edited in `.env` we'll create some database objects. [Yes, a setup wizard needs to be built!].

First let's create the password for the admin user. The following will create a secure random password and hash it with bcrypt:

```sh
USERNAME=admin
USEREMAIL=your@email.address
IXPM_ADMIN_PW="$( openssl rand -base64 12 )"
ADMIN_PW_SALT="$( openssl rand -base64 16 )"
HASH_PW=$( php -r "echo escapeshellarg( crypt( '${IXPM_ADMIN_PW}', sprintf( '\$2a\$%02d\$%s', 10, substr( '${ADMIN_PW_SALT}', 0, 22 ) ) ) );" )
echo Your password is: $IXPM_ADMIN_PW
```

The following is taken from the IXP Manager installation script:

```mysql
mysql -u root "-p${MYSQL_ROOT_PW}" $DBNAME <<END_SQL
INSERT INTO ixp ( name, shortname, address1, country )
    VALUES ( '${IXPNAME}', '${IXPSNAME}', '${IXPCITY}', '${IXPCOUNTRY}' );
SET @ixpid = LAST_INSERT_ID();

INSERT INTO infrastructure ( ixp_id, name, shortname, isPrimary )
    VALUES ( @ixpid, 'Infrastructure #1', '#1', 1 );
SET @infraid = LAST_INSERT_ID();

INSERT INTO company_registration_detail ( registeredName ) VALUES ( '${IXPNAME}' );
SET @crdid = LAST_INSERT_ID();

INSERT INTO company_billing_detail ( billingContactName, invoiceMethod, billingFrequency )
    VALUES ( '${NAME}', 'EMAIL', 'NOBILLING' );
SET @cbdid = LAST_INSERT_ID();

INSERT INTO cust ( name, shortname, type, abbreviatedName, autsys, maxprefixes, peeringemail, nocphone, noc24hphone,
        nocemail, nochours, nocwww, peeringpolicy, corpwww, datejoin, status, activepeeringmatrix, isReseller,
        company_registered_detail_id, company_billing_details_id )
    VALUES ( '${IXPNAME}', '${IXPSNAME}', 3, '${IXPSNAME}', '${IXPASN}', 100, '${IXPPEEREMAIL}', '${IXPNOCPHONE}',
        '${IXPNOCPHONE}', '${IXPNOCEMAIL}', '24x7', '', 'mandatory', '${IXPWWW}', NOW(), 1, 1, 0, @crdid, @cbdid );
SET @custid = LAST_INSERT_ID();

INSERT INTO customer_to_ixp ( customer_id, ixp_id ) VALUES ( @custid, @ixpid );

INSERT INTO user ( custid, username, password, email, privs, disabled, created )
    VALUES ( @custid, '${USERNAME}', ${HASH_PW}, '${USEREMAIL}', 3, 0, NOW() );
SET @userid = LAST_INSERT_ID();

INSERT INTO contact ( custid, name, email, created, user_id ) VALUES ( @custid, '${NAME}', '${USEREMAIL}', NOW(), @userid );
END_SQL
```

And finally seed the database:

```sh
cd $IXPROOT
php artisan db:seed --class=IRRDBs
php artisan db:seed --class=Vendors
php artisan db:seed --class=ContactGroups
```

## File Permissions

The web server needs write access to some directories:

```sh
cd $IXPROOT
chown -R www-data: var/ storage/ bootstrap/cache/ database/Proxies/
chmod -R u+rwX var/ storage/ bootstrap/cache/ database/Proxies/
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
* PLEASE TELL US! We'd like to add you to the users list at http://www.ixpmanager.org/users.php - just drop us an email to `operations <at> inex <dot> ie`.
