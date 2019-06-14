
# Routinator 3000

**Routinator 3000** is a [RPKI](/features/rpki.md) relying party software (aka RPKI Validator) written in Rust by the good folks at [NLnet Labs](https://www.nlnetlabs.nl/projects/rpki/routinator/). These instructions reflect Routinator 0.4, which is set up and started differently than older versions. This mostly follows [their own GitHub instructions](https://github.com/NLnetLabs/routinator) and [documentation](https://rpki.readthedocs.io/en/latest/routinator/).

We use a standard Ubuntu 18.04 installation (selecting the minimal virtual server option), 2 vCPUs, 2GB RAM, 10GB LVM hard drive.

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
Routinator 0.4
```
Routinator needs to prepare its working environment via the `init` command, which will set up both
the directory for the local RPKI cache as well as the TAL directory. Running it will prompt you to 
agree to the [ARIN Relying Party Agreement (RPA)](https://www.arin.net/resources/manage/rpki/tal/) 
so it can install the ARIN TAL along with the other four RIR TALs:

```sh
/srv/routinator/.cargo/bin/routinator init
```

To agree with the ARIN RPA, run:

```sh
/srv/routinator/.cargo/bin/routinator init --accept-arin-rpa
```

You can then test by running the following (this command prints the validated ROA payloads
and increases the log level to show the process in detail at least once):

```sh
/srv/routinator/.cargo/bin/routinator -v vrps
```

To upgrade Routinator, you reinstall it (`-f` to overwrite the older version):

```sh
cargo install -f routinator
```

After you upgrade, kill the running version of Routinator and start it again.

Note that in the above we are using the (sensible) configuration defaults. Read Routinator's own [documentation](https://rpki.readthedocs.io/en/latest/routinator/) if you want to change these.

Start Routinator's RTR and HTTP service with:

```
/srv/routinator/.cargo/bin/routinator server --rtr 192.0.2.13:3323 --rtr [2001:db8::13]:3323 --http 192.0.2.13:8080
```

It will stay attached unless you run it with `-d` (for daemon) to start in the background. You can see log messages using:

```sh
cat /var/log/syslog | grep routinator
```

When it starts, there is a webserver on port 8080 - see [the documentation for the available endpoints](https://rpki.readthedocs.io/en/latest/routinator/running.html#running-the-http-service).

## Starting on Boot

To have this service start at boot, we create systemd service files:


```sh
cat <<ENDL >/etc/systemd/system/rpki-routinator.service
[Unit]
Description=RPKI Routinator

[Service]
Restart=always
RestartSec=60

WorkingDirectory=/srv/routinator

User=routinator

StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=rpki-routinator

ExecStart=/srv/routinator/.cargo/bin/routinator server --rtr 192.0.2.13:3323 --rtr [2001:db8::13]:3323 --http 192.0.2.13:8080



[Install]
WantedBy=multi-user.target

ENDL
```

And then we enable it to start on boot:

```sh
systemctl enable rpki-routinator.service
```

## Monitoring

We add Nagios http checks for port 8080 (HTTP) to our monitoring platform. We also add a `check_tcp` test for the RPKI-RTR port 3323.
