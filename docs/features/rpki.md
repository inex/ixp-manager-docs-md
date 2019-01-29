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
    echo Routinater not running! Restarting it...
    /srv/routinator/.cargo/bin/routinator rtrd -l 192.0.2.13:3323 -l [2001:db8::13]:3323
fi
```

We save this as `/usr/local/bin/watch-routinator.sh` and `chmod a+x`. We then run it hourly via the following entry in `/etc/crontab`:

```
13 *    * * *   routinator      /usr/local/bin/watch-routinator.sh
```
