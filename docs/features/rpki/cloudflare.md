
# Cloudflare's RPKI Toolkit

Cloudflare created their own RPKI toolkit which, similar to RIPE's, is split into two elements:

1. **GoRTR** is the daemon that implements the RPKI-RTR protocol to distribute validated ROAs to your routers.
2. **OctoRPKI** is the validator which pulls the signed ROAs from the trust anchors and validates them and then makes them available to GoRTR.

**NB:** Before you proceed further, you should [read Cloudflare's own introduction to this toolkit](https://blog.cloudflare.com/cloudflares-rpki-toolkit/).

We use a standard Ubuntu 20.04 installation (selecting the minimal virtual server option), 2 vCPUs, 2GB RAM, 20GB LVM hard drive.

Cloudflare provide pre-built packages for installation - visit the following URLs and download the appropriate packages for your operating system:

* https://github.com/cloudflare/cfrpki/releases
* https://github.com/cloudflare/gortr/releases

As of late November 2020, the following packages are available to install:

```sh
wget https://github.com/cloudflare/cfrpki/releases/download/v1.2.2/octorpki_1.2.2_amd64.deb
wget https://github.com/cloudflare/gortr/releases/download/v0.14.7/gortr_0.14.7_amd64.deb
dpkg -i octorpki_1.2.2_amd64.deb gortr_0.14.7_amd64.deb
```


## OctoRPKI

You now need to install the ARIN file manually:

1. Visit https://www.arin.net/resources/rpki/tal.html
2. Download the TAL in RFC 7730 format
3. Place it in `/usr/share/octorpki/tals/arin.tal`


You can now run the validator via the following command:

```sh
# start the service:
systemctl start octorpki

# see and tail the logs
journalctl -fu octorpki

# enable to start on server boot:
systemctl enable octorpki.service
```

**NB:** OctoRPKI listens as a web service by default on port `8081`. It's possible to change this port by adding `OCTORPKI_ARGS=-http.addr :8080` to `/etc/default/octorpki` if required.

As it starts up, there is some info available as JSON under `http://[hostname/ip address]:8081/infos` and the ROAs can be seen as JSON via `http://[hostname/ip address]:8081/output.json` after ~5mins.



## GoRTR

To start GoRTR (once OctoRPKI is configured and running), we first edit `/etc/default/gortr`:

```
GORTR_ARGS=-bind :3323 -verify=false -cache http://localhost:8081/output.json -metrics.addr :8082
```

You can now run the GoRTR daemon via the following command:

```sh
# start the service:
systemctl start gortr

# see and tail the logs
journalctl -fu gortr

# enable to start on server boot:
systemctl enable gortr.service
```


Once GoRTR starts up, metrics are available from http://[hostname/ip address]:8082/metrics.



## Monitoring

We add Nagios http checks for ports 8081 (OctoRPKI) and 8082 (GoRTR) to our monitoring platform. We also add a `check_tcp` test for GoRTR port 3323.
