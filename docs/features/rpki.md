# RPKI

***DEVELOPMENT NOTES***







## Installing an RPKI Server

Standard Ubuntu 18.04 install (minimal virtual server, 2 vCPUs, 2GB RAM, 10GB LVM hard drive).



### Routinator 3000

**Routinator 3000** is a RPKI relying party software (aka RPKI Validator) written in Rust by the good folks at [NLnet Labs](https://www.nlnetlabs.nl/projects/rpki/routinator/). To install this we mostly follow [their own GitHub instructions](https://github.com/NLnetLabs/routinator).

Rather than running Routinator as the root user, we create a dedicated user:

```sh
useradd -c 'Routinator 3000' -d /srv/routinator -m -s /bin/bash -u 1100 routinator
```

We then install the required software. `build-essential` is a Ubuntu alias package that installs the common C software build suite. `cargo` is Rust's package manager and installing that automatically installs other Rust dependancies.

```sh
apt install -y build-essential cargo
```

To install Routinator, we then switch to the `routinator` user and use Cargo to build and install it:

```sh
sudo su - routinator
cargo install routinator
```

To check if this works, run the following (and note the path to the `routinator` binary):

```sh
routinator@rpki01:~$ /srv/routinator/.cargo/bin/routinator -V
Routinator 0.2.1
```

Also run the following to get instructions for downloading and installing the ARIN TAL:

```sh
/srv/routinator/.cargo/bin/routinator vrps
```

Installing the ARIN file is done by:

1. Visiting https://www.arin.net/resources/rpki/tal.html
2. Downloading the TAL in RFC 7730 format
3. Placing it in `/srv/routinator/.rpki-cache/tals/arin.tal`

You can then test by running the following again (this command prints the validated ROA payloads):

```sh
/srv/routinator/.cargo/bin/routinator vrps
```

To upgrade Routinator, you reinstall it (`-f` to overwrite the older version):

```sh
cargo install -f routinator
```

After you upgrade, kill the running version of Routinator and start it again.

Note that in the above we are using the (sensible) configuration defaults. Read Routinator's own documentation if you want to change these.

Start Routinator's RTR service with:

```
/srv/routinator/.cargo/bin/routinator rtrd -a -l 192.0.2.13:3323 -l [2001:db8::13]:3323
```

It will immediately start in the background. The `-a` switch will keep it in the foreground. You can see log messages using:

```sh
cat /var/log/syslog | grep routinator
```

To have the service start at boot, we do the following (**NB:** ensure you have nothing in `rc.local` as the following overwrites it):

```sh
cat <<ENDL >/etc/rc.local
#! /bin/bash

# Start Routinator
/usr/bin/sudo -iu routinator /srv/routinator/.cargo/bin/routinator rtrd -l 192.0.2.13:3323 -l [2001:db8::13]:3323

ENDL

chmod a+x /etc/rc.local
```

We also use a simple watcher script to restart Routinator in case it dies during production use. Here's a simple example:

```sh
#! /bin/bash

# Simple script to make sure Routinator stays running.
# Note we test for X2X as we expect a socket for ipv4 and ipv6 at INEX

if [[ "X$(/bin/netstat -lpn | grep 3323 | grep routinator | wc -l)X" != "X2X" ]]; then
    echo Routinator not running! Restarting it...
    /srv/routinator/.cargo/bin/routinator rtrd -l 192.0.2.13:3323 -l [2001:db8::13]:3323
fi
```

We save this as `/usr/local/bin/watch-routinator.sh` and `chmod a+x`. We then run it hourly via the following entry in `/etc/crontab`:

```
13 *    * * *   routinator      /usr/local/bin/watch-routinator.sh
```


## RIPE NCC RPKI Validator 3

The second RPKI-RTR implementation we have tested and support is RIPE's [RPKI Validator 3](https://github.com/RIPE-NCC/rpki-validator-3).

RIPE provides CentOS7 RPMs for production builds but as we tend to use Ubuntu LTS for our servers, we will describe an installation using the generic builds here. You can read RIPE's [CentOS7 installation details here](https://github.com/RIPE-NCC/rpki-validator-3/wiki/RIPE-NCC-RPKI-Validator-3-Production) and their [own generic install details here](https://github.com/RIPE-NCC/rpki-validator-3/wiki/Running-the-generic-builds) (which are the ones we worked from for these Ubuntu 18.04 LTS instructions).

Like with Routinator above, we will use a non-root user to run the daemons.

```sh
useradd -c 'RIPE NCC RPKI Validator' -d /srv/ripe-rpki-validator -m -s /bin/bash -u 1100 ripe
```

Download and extract the latest production releases [from here](https://ftp.ripe.net/tools/rpki/validator3/prod/generic/):

```sh
cd /srv/ripe-rpki-validator
wget https://ftp.ripe.net/tools/rpki/validator3/prod/generic/rpki-rtr-server-latest-dist.tar.gz
tar zxf rpki-rtr-server-latest-dist.tar.gz
wget https://ftp.ripe.net/tools/rpki/validator3/prod/generic/rpki-validator-3-latest-dist.tar.gz
tar zxf rpki-validator-3-latest-dist.tar.gz
```

When you extract these, you'll find they create directories named by their version. As we will reference these in various scripts, we will alias these directories so we do not need to update the scripts on an upgrade of the software. In our example case, the version was `3.0-255` so we do the following (and also ensure the permissions are correct):

```sh
ln -s rpki-rtr-server-3.0-355 rpki-rtr-server-3
ln -s rpki-validator-3.0-355 rpki-validator-3
chown -R ripe: /srv/ripe-rpki-validator
```

The requirements for RPKI Validator 3 are OpenJDK and rsync. For Ubuntu 18.04 that means:

```sh
apt install -y openjdk-8-jre rsync curl
```

We will want to keep configuration changes and the database across upgrades. For this we:

```sh
# move the config and replace it with a link:
cd /srv/ripe-rpki-validator
mv rpki-validator-3/conf/application.properties rpki-validator-3.conf
ln -s /srv/ripe-rpki-validator/rpki-validator-3.conf \
    /srv/ripe-rpki-validator/rpki-validator-3/conf/application.properties

# And do the same for the datebase:
mv rpki-validator-3/db .
ln -s /srv/ripe-rpki-validator/db /srv/ripe-rpki-validator/rpki-validator-3/db

# And do the same for rpki-rtr-server-3:
mv rpki-rtr-server-3/conf/application.properties rpki-rtr-server-3.conf
ln -s /srv/ripe-rpki-validator/rpki-rtr-server-3.conf \
    /srv/ripe-rpki-validator/rpki-rtr-server-3/conf/application.properties

# again, ensure file ownership is okay
chown -R ripe: /srv/ripe-rpki-validator
```

We then edit `/srv/ripe-rpki-validator/rpki-validator-3.conf` and change the following configuration options:

1. `server.port` and `server.address` if you want to access the web interface directly. Commenting `server.address` out makes it listen on all interfaces.
2. `spring.datasource.url` to `/srv/ripe-rpki-validator/db/rpki-validator.h2`.

And we edit ``/srv/ripe-rpki-validator/rpki-rtr-server-3.conf` and set:
1. set `server.port` and `server.address` as required (note this is for the API, not the RTR protocol). `server.address=` listens on all interfaces.
2. set `rtr.server.address` and `rtr.server.port` as required (this is the RTR protocol). `rtr.server.address=::` listens on all interfaces.


You should now be able to start the Validator and RTR daemons:

```sh
# as the RIPE user
su - ripe

cd /srv/ripe-rpki-validator/rpki-validator-3
./rpki-validator-3.sh

cd /srv/ripe-rpki-validator/rpki-rtr-server-3
./rpki-rtr-server.sh
```

Like Routinator, we need to manually install the ARIN TAL by:

1. Visiting https://www.arin.net/resources/rpki/tal.html
2. Downloading the TAL in *RIPE NCC RPKI Validator format* format
3. Installing it using the command:
    ```
    /srv/ripe-rpki-validator/rpki-validator-3/upload-tal.sh arin-ripevalidator.tal http://localhost:8080/
    ```

We use systemd to ensure both daemons start automatically:


```sh
cat <<ENDL >/etc/systemd/system/rpki-validator-3.service
[Unit]
Description=RPKI Validator
After=network.target

[Service]
Environment=JAVA_CMD=/usr/bin/java
ExecStart=/srv/ripe-rpki-validator/rpki-validator-3/rpki-validator-3.sh

# prevent restart in case there's a problem
# with the database or binding to socket
RestartPreventExitStatus=7

User=ripe

[Install]
WantedBy=multi-user.target
ENDL

systemctl enable rpki-validator-3.service
systemctl start rpki-validator-3.service


cat <<ENDL >/etc/systemd/system/rpki-rtr-server-3.service
[Unit]
Description=RPKI RTR
After=rpki-validator-3.service

[Service]
Environment=JAVA_CMD=/usr/bin/java
ExecStart=/srv/ripe-rpki-validator/rpki-rtr-server-3/rpki-rtr-server.sh

# prevent restart in case there's a problem
# with the database or binding to socket
RestartPreventExitStatus=7

User=ripe

[Install]
WantedBy=multi-user.target
ENDL

systemctl enable rpki-rtr-server-3.service
systemctl start rpki-rtr-server-3.service
```

You can see log messages using:

```sh
cat /var/log/syslog | grep rpki-validator
cat /var/log/syslog | grep rpki-rtr
```
