
# Routinator 3000

**Routinator 3000** is a [RPKI](/features/rpki.md) relying party software (aka RPKI Validator) written in Rust by the good folks at [NLnet Labs](https://www.nlnetlabs.nl/projects/rpki/routinator/). These instructions reflect Routinator 0.7.1 (on Ubuntu 20.04). This mostly follows [their own GitHub instructions](https://github.com/NLnetLabs/routinator) and [documentation](https://rpki.readthedocs.io/en/latest/routinator/).

We use a standard Ubuntu 20.04 installation (selecting the minimal virtual server option), 2 vCPUs, 2GB RAM, 20GB LVM hard drive.

Rather than running Routinator as the root user, we create a dedicated user:

```sh
useradd -c 'Routinator 3000' -d /srv/routinator -m -s /bin/bash -u 1100 routinator
```

We then install the required software. `build-essential` is a Ubuntu alias package that installs the common C software build suite. `cargo` is Rust's package manager and installing that automatically installs other Rust dependencies.

```sh
apt install -y build-essential cargo rsync
```

You should have rust version >=1.43.0 installed (check with `rustc -V`).

To install Routinator, we then switch to the `routinator` user and use Cargo to build and install it:

```sh
sudo su - routinator
cargo install --locked routinator
```

To check if this works, run the following (and note the path to the `routinator` binary):

```sh
routinator@rpki01:~$ /srv/routinator/.cargo/bin/routinator -V
Routinator 0.7.1
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
cargo install --locked --force routinator
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

To have this service start at boot, we create systemd service files.

**Edit this to reflect your correct IP address(es).**


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

## HTTP Interface

The following is copied [from Routinator's man page](https://nlnetlabs.nl/documentation/rpki/routinator/). As a future work fixme, this should be used for better monitoring that just `check_tcp` above.

```
HTTP SERVICE
       Routinator  can provide an HTTP service allowing to fetch the Validated
       ROA Payload in various formats. The service does not support HTTPS  and
       should only be used within the local network.

       The service only supports GET requests with the following paths:


       /metrics
              Returns  a  set  of  monitoring  metrics  in  the format used by
              Prometheus.

       /status
              Returns the current status of the Routinator instance.  This  is
              similar  to  the  output  of the /metrics endpoint but in a more
              human friendly format.

       /version
              Returns the version of the Routinator instance.

       /api/v1/validity/as-number/prefix
              Returns a JSON object describing whether the route  announcement
              given  by its origin AS number and address prefix is RPKI valid,
              invalid, or not found.  The returned object is  compatible  with
              that  provided by the RIPE NCC RPKI Validator. For more informa-
              tion, see  https://www.ripe.net/support/documentation/developer-
              documentation/rpki-validator-api

       /validity?asn=as-number&prefix=prefix
              Same as above but with a more form-friendly calling convention.


       In  addition, the current set of VRPs is available for each output for-
       mat at a path with the same name as the output format.  E.g.,  the  CSV
       output is available at /csv.

       These paths accept filter expressions to limit the VRPs returned in the
       form of a query string. The field filter-asn can be used to filter  for
       ASNs  and  the  field filter-prefix can be used to filter for prefixes.
       The fields can be repeated multiple times.

       This works in the same way as the options of the same name to the  vrps
       command.

```
