
# Routinator 3000

**Routinator 3000** is a [RPKI](/features/rpki.md) relying party software (aka RPKI Validator) written in Rust by the good folks at [NLnet Labs](https://www.nlnetlabs.nl/projects/rpki/routinator/). These instructions reflect Routinator 0.8.2 (on Ubuntu 20.04). This mostly follows [their own GitHub instructions](https://github.com/NLnetLabs/routinator) and [documentation](https://rpki.readthedocs.io/en/latest/routinator/).

We use a standard Ubuntu 20.04 installation (selecting the minimal virtual server option), 2 vCPUs, 2GB RAM, 20GB LVM hard drive.

Add the apt repo to the system by creating a file called `/etc/apt/sources.list.d/routinator.list` with the following contents:

```
deb [arch=amd64] https://packages.nlnetlabs.nl/linux/debian/ stretch main
deb [arch=amd64] https://packages.nlnetlabs.nl/linux/debian/ buster main
deb [arch=amd64] https://packages.nlnetlabs.nl/linux/ubuntu/ xenial main
deb [arch=amd64] https://packages.nlnetlabs.nl/linux/ubuntu/ bionic main
deb [arch=amd64] https://packages.nlnetlabs.nl/linux/ubuntu/ focal main
```

Then add the NLNetLabs package key to the system:

```
sudo apt update && apt-get install -y gnupg2
wget -qO- https://packages.nlnetlabs.nl/aptkey.asc | sudo apt-key add -
sudo apt update
```

Note that the first `apt update` will return a bunch of errors.  The second update should run without errors, once the key has been added.

We then install the required software:

```
sudo apt install routinator
sudo routinator-init
```

Alternatively, if you plan to agree with the ARIN RPA, run:

```sh
sudo routinator-init --accept-arin-rpa
```

By default, Routinator listens only on TCP sockets on 127.0.0.1.  If you want other devices
to be able to access the service, it needs to listen to the wildcard socket.


If you're running Linux, you can configure Routinator to listen to both ipv4
and ipv6 wildcard sockets using the following configuration lines in
`/etc/routinator/routinator.conf`:

```
rtr-listen = [ "[::]:3323" ]
http-listen = [ "[::]:8080" ]
```

If you're running an operating system other than Linux, you'll need separate entries for
ipv4 and ipv6:

```
rtr-listen = [ "127.0.0.1:3323", "[::]:3323" ]
http-listen = [ "127.0.0.1:8080", "[::]:8080" ]
```

You can then test by running the following command, which prints the validated ROA payloads
and increases the log level to show the process in detail:

```sh
/usr/bin/routinator --config /etc/routinator/routinator.conf -v vrps
```

## Starting on Boot

To have this service start at boot:

```
systemctl enable routinator
systemctl start routinator
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
