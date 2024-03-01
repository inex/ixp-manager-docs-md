# OpenBSD's RPKI Validator rpki-client

The OpenBSD project created a free and easy-to-use RPKI validator named **[rpki-client](https://www.rpki-client.org/)**.

Deployment is split into two elements:

1. **rpki-client** is the validator which pulls the Signed Objects from the RPKI repositories and validates them and then makes them available to StayRTR.
2. **StayRTR** is the daemon that implements the RPKI-RTR protocol to distributes Validated ROA Payloads to your routers.

We use a standard Debian Sid (unstable) installation, 2 vCPUs, 2GB RAM, 20GB LVM hard drive.
Debian provides pre-built packages for installation.

As of early March 2024, the following packages can easily be installed:

```sh
$ sudo apt install rpki-client stayrtr
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

Running rpki-client the first time might take a few minutes.

## StayRTR

To start StayRTR (once rpki-client is configured and running), we first edit `/etc/default/stayrtr`:

```
STAYRTR_ARGS=-bind :3323 -cache /var/lib/rpki-client/json -metrics.addr :8082
```

You can now run the StayRTR daemon via the following command:

```sh
# start the service:
systemctl restart stayrtr

# see and tail the logs
journalctl -fu stayrtr
```

Once rpki-client completed its initial run, and StayRTR starts up, metrics are available from http://[hostname/ip address]:8082/metrics.

## Monitoring

We add Nagios http checks for and 8082 (StayRTR) to our monitoring platform. We also add a `check_tcp` test for StayRTR port 3323.

Rpki-client produces a statistics file in OpenMetrics format in `/var/lib/rpki-client/metrics` for use with Grafana.
