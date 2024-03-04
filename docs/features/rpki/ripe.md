## RIPE NCC RPKI Validator 3

???+ danger
    The **RIPE NCC RPKI Validator 3** has been [deprecated](https://www.ripe.net/publications/news/ending-support-for-the-ripe-ncc-rpki-validator/) and should not be used. 


The **RIPE NCC RPKI Validator 3** is a [RPKI](/features/rpki.md) relying party software (aka RPKI Validator). While  RIPE's [RPKI Validator 3](https://github.com/RIPE-NCC/rpki-validator-3) is a RPKI-RTR implementation we have tested and support, we found it buggy in production (as of April 2019 it consumed increasing amounts of disk space and crashed regularly). These instructions reflect INEX's production installation from early 2019.

RIPE provides CentOS7 RPMs for production builds but as we tend to use Ubuntu LTS for our servers, we will describe an installation using the generic builds here. You can read RIPE's [CentOS7 installation details here](https://github.com/RIPE-NCC/rpki-validator-3/wiki/RIPE-NCC-RPKI-Validator-3-Production) and their [own generic install details here](https://github.com/RIPE-NCC/rpki-validator-3/wiki/Running-the-generic-builds) (which are the ones we worked from for these Ubuntu 18.04 LTS instructions).

We use a standard Ubuntu 18.04 installation (selecting the minimal virtual server option), 2 vCPUs, 2GB RAM, 10GB LVM hard drive.

We will use a non-root user to run the daemons:

```sh
useradd -c 'RIPE NCC RPKI Validator' -d /srv/ripe-rpki-validator \
    -m -s /bin/bash -u 1100 ripe
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

And we edit `/srv/ripe-rpki-validator/rpki-rtr-server-3.conf` and:

1. set `server.port` and `server.address` as required (note this is for the API, not the RTR protocol). `server.address=` listens on all interfaces.
2. set `rtr.server.address` and `rtr.server.port` as required (this is the RTR protocol).  
`rtr.server.address=::` listens on all interfaces.


You should now be able to start the Validator and RTR daemons:

```sh
# as the RIPE user
su - ripe

cd /srv/ripe-rpki-validator/rpki-validator-3
./rpki-validator-3.sh

cd /srv/ripe-rpki-validator/rpki-rtr-server-3
./rpki-rtr-server.sh
```

We need to manually install the ARIN TAL by:

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

We separately add the server and the RIPE daemons to our standard monitoring and alerting tools.
