
# Cloudflare's RPKI Toolkit

Cloudflare created their own RPKI toolkit which, similar to RIPE's, is split into two elements:

1. **GoRTR** is the damon that implements the RPKI-RTR protocol to distribute validated ROAs to your routers.
2. **OctoRPKI** is the validator which pulls the signed ROAs from the trust anchors and validates them and then makes them available to GoRTR.

**NB:** Before you proceed further, you should [read Cloudflare's own introduction to this toolkit](https://blog.cloudflare.com/cloudflares-rpki-toolkit/).

We use a standard Ubuntu 18.04 installation (selecting the minimal virtual server option), 2 vCPUs, 2GB RAM, 10GB LVM hard drive. Not that INEX at this point has not embraced Docker for production services so our install does not use Cloudflare's docker options.

Rather than running these daemons as the root user, we create a dedicated user:

```sh
useradd -c 'cloudflare' -d /srv/cloudflare -m -s /bin/bash -u 1102 cloudflare
```

We now install packages we need:

```sh
apt install golang git rsync ca-certificates
```

Note that in the following, we are not signing the JSON file or ROAs that OctoRPKI generates and this not validating this in GoRTR. The reason for this as primarily that it *just wouldn't work* (May 2019) but also as this is a same server operation and no other tools are using the JSON.

## OctoRPKI

To install OctoRPKI, su to the target user and proceed as follows (we assume all  commands are executed from `/srv/cloudflare`):

```sh
sudo su - cloudflare

go get github.com/cloudflare/cfrpki/cmd/octorpki

# test:
./go/bin/octorpki -h

# create the directories we need:
mkdir tals && mkdir cache && touch rrdp.json

# copy files we need from the OctoRPKI repository:
cp go/src/github.com/cloudflare/cfrpki/cmd/octorpki/tals/* tals/
```

You now need to install the ARIN file manually, sigh:

1. Visiting https://www.arin.net/resources/rpki/tal.html
2. Downloading the TAL in RFC 7730 format
3. Place it in `/srv/cloudflare/tals/arin.tal`


You can now run the validator via the following command *(and I'm showing the start of some of the sample output)*:

```sh
$ ./go/bin/octorpki -mode server -output.sign=0
INFO[0000] Validator started
INFO[0000] Serving HTTP on :8080/output.json
...
```

As it starts up, there is some info available as JSON under http://localhost:8080/infos and the ROAs can be seen as JSON via http://localhost:8080/output.json after ~5mins.



## GoRTR

To install GoRTR (once OctoRPKI is installed and running), we proceed as follows and assume you are su'd to `cloudflare` and your current directory is `/srv/cloudflare`:

```sh
go get github.com/cloudflare/gortr/cmd/gortr
```

You can run it now with:

```sh
./go/bin/gortr -bind :3323                                \
               -verify=0                                  \
               -cache http://localhost:8080/output.json   \
               -metrics.addr :8081
```

Once GoRTR starts up, metrics are available from http://127.0.0.1:8081/metrics.

## Starting on Boot

To have these services start at boot, we create systemd service files:


```sh
cat <<ENDL >/etc/systemd/system/cloudflare-octorpki.service
[Unit]
Description=Cloudflare OctoRPKI Validator

[Service]
Restart=always
RestartSec=60

WorkingDirectory=/srv/cloudflare

User=cloudflare

StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cloudflare-octorpki

ExecStart=/srv/cloudflare/go/bin/octorpki -mode server -output.sign=0



[Install]
WantedBy=multi-user.target

ENDL
```

```
cat <<ENDL >/etc/systemd/system/cloudflare-gortr.service
[Unit]
Description=Cloudflare GoRTR
After=cloudflare-octorpki.service

[Service]
Restart=always
RestartSec=60

WorkingDirectory=/srv/cloudflare

User=cloudflare

StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cloudflare-gortr

ExecStartPre=/bin/sleep 30

ExecStart=/srv/cloudflare/go/bin/gortr -bind :3324 -verify=0 -cache http://localhost:8080/output.json -metrics.addr :8081 -refresh=120


[Install]
WantedBy=multi-user.target

ENDL
```

And then we enable for start on boot with:

```sh
systemctl enable cloudflare-octorpki.service
systemctl enable cloudflare-gortr.service
```

Note that:

* we have a sleep on gortr of 30 seconds to give OctoRPKI a chance to start;
* even still, it may not be ready in which case gortr will retry every two minutes (`-refresh=120`).

## Monitoring

We add Nagios http checks for ports 8080 (OctoRPKI) and 8081 (GoRTR) to our monitoring platform. We also add a `check_tcp` test for GoRTR port 3323.
