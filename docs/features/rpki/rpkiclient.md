# OpenBSD's RPKI Validator rpki-client

The OpenBSD project created a free and easy-to-use RPKI validator named **[rpki-client](https://www.rpki-client.org/)**.

Deployment is split into two elements:

1. **StayRTR** is the daemon that implements the RPKI-RTR protocol to distribute validated ROAs to your routers.
2. **rpki-client** is the validator which pulls the Signed Objects from the RPKI repositories and validates them and then makes them available to StayRTR.

We use a standard Debian Sid (unstable) installation, 2 vCPUs, 2GB RAM, 20GB LVM hard drive.

Debian provides pre-built packages for installation.

As of early March 2024, the following packages can easily be installed:

```sh
$ sudo apt install stayrtr rpki-client rpki-trust-anchors
```

## rpki-trust-anchors

You'll need to confirm whether you'd like to install the ARIN TAL.

You can now run the validator via the following command:

## rpki-client

```sh
# start the service:
systemctl start rpki-client &

# see and tail the logs
journalctl -fu rpki-client
```

## StayRTR

To start StayRTR (once rpki-client is configured and running), we first edit `/etc/default/stayrtr`:

```
STAYRTR_ARGS=-bind :3323 -cache /var/lib/rpki-client/json -metrics.addr :8082
```

You can now run the StayRTR daemon via the following command:

```sh
# start the service:
systemctl enable stayrtr
systemctl restart stayrtr

# see and tail the logs
journalctl -fu stayrtr
```

Once StayRTR starts up, metrics are available from http://[hostname/ip address]:8082/metrics.

## Monitoring

We add Nagios http checks for and 8082 (StayRTR) to our monitoring platform. We also add a `check_tcp` test for StayRTR port 3323.

Rpki-client produces a statistics file in OpenMetrics format in `/var/lib/rpki-client/metrics` for use with Grafana.
