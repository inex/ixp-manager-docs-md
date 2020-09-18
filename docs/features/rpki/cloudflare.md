
# Cloudflare's RPKI Toolkit

Cloudflare created their own RPKI toolkit which, similar to RIPE's, is split into two elements:

1. **GoRTR** is the daemon that implements the RPKI-RTR protocol to distribute validated ROAs to your routers.
2. **OctoRPKI** is the validator which pulls the signed ROAs from the trust anchors and validates them and then makes them available to GoRTR.

**NB:** Before you proceed further, you should [read Cloudflare's own introduction to this toolkit](https://blog.cloudflare.com/cloudflares-rpki-toolkit/).

We use a standard Ubuntu 20.04 installation (selecting the minimal virtual server option), 2 vCPUs, 2GB RAM, 20GB LVM hard drive.

Cloudflare provide pre-built packages for installation - visit the following URLs and download the appropriate packages for your operating system:

* https://github.com/cloudflare/cfrpki/releases
* https://github.com/cloudflare/gortr/releases

In my case, with Ubuntu 20.04 in September 2020, I ended up installing the following:

```sh
wget https://github.com/cloudflare/cfrpki/releases/download/v1.1.4/octorpki_1.1.4_amd64.deb
wget https://github.com/cloudflare/gortr/releases/download/v0.14.6/gortr_0.14.6_amd64.deb
dpkg -i gortr_0.14.6_amd64.deb octorpki_1.1.4_amd64.deb
```


## OctoRPKI

You now need to install the ARIN file manually, sigh:

1. Visiting https://www.arin.net/resources/rpki/tal.html
2. Downloading the TAL in RFC 7730 format
3. Place it in `/usr/share/tals/arin.tal`


You can now run the validator via the following command *(and I'm also showing how to see the log)*:

```sh
# start the service:
systemctl start octorpki

# see and tail the logs
journalctl -fu octorpki

# enable to start on server boot:
systemctl enable octorpki.service
```

At the time of writing with the above mentioned versions, we have the following error in the

```
Error adding Resource tals/arin.tal: illegal base64 data at input byte 4
```

This is referenced in the follow [GitHub issue for octorpki #53](https://github.com/cloudflare/cfrpki/issues/53) and is solved by editing `/usr/share/tals/arin.tal` and removing the line starting `https://...` and then restart (`systemctl restart octorpki`).

As it starts up, there is some info available as JSON under `http://[hostname/ip address]:8080/infos` and the ROAs can be seen as JSON via `http://[hostname/ip address]:8080/output.json` after ~5mins.


## GoRTR

To start GoRTR (once OctoRPKI is configured and running), we first edit `/etc/default/gortr`:

```
GORTR_ARGS=-bind :3323 -verify=false -cache http://localhost:8080/output.json -metrics.addr :8081
```

You can now run the GoRTR daemon via the following command *(and I'm also showing how to see the log)*:

```sh
# start the service:
systemctl start gortr

# see and tail the logs
journalctl -fu gortr

# enable to start on server boot:
systemctl enable gortr.service
```


Once GoRTR starts up, metrics are available from http://[hostname/ip address]:8081/metrics.



## Monitoring

We add Nagios http checks for ports 8080 (OctoRPKI) and 8081 (GoRTR) to our monitoring platform. We also add a `check_tcp` test for GoRTR port 3323.
