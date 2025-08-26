# Grapher - Introduction

**IXP Manager** generates all of its graphs using its own graphing system called *Grapher*. 

*Grapher* is a complete rewrite of all previous graphing code and includes:

- API access to graphs and graph statistics
- multiple backends (such as MRTG, sflow, Smokeping) with dynamic resolution of appropriate backend
- configuration generation where required
- consistent and flexible OOP design

To date, we have developed the following reference backend implementations:

1. ``dummy`` - a dummy grapher that just provides a placeholder graph for all possible graph types;
2. ``mrtg`` - MRTG graphing using either the log or rrd backend. Use cases for MRTG are L2 interface statistics for bits / packets / errors / discards / broadcasts per second. Aggregate graphs for customer LAGs, overall customer traffic, all traffic over a switch / infrastructure / the entire IXP are all supported;
3. ``sflow`` - while the MRTG backend looks at layer 2 statistics, sflow is used to provide layer 3 statistics such as per protocol (IPv4/6) graphs and peer to peer graphs;
4. ``smokeping`` - which creates latency graphs and this replaces the previous way we used to access Smokeping graphs.

In a typical production environment, you would implement MRTG, Smokeping and sflow to provide the complete set of features.

## Configuration

There are only a handful of configuration options required and a typical and complete `$IXPROOT/.env` would look like the following:

```
GRAPHER_BACKENDS="mrtg|sflow|smokeping"
GRAPHER_CACHE_ENABLED=true

GRAPHER_BACKEND_MRTG_DBTYPE="rrd"
GRAPHER_BACKEND_MRTG_WORKDIR="/srv/mrtg"
GRAPHER_BACKEND_MRTG_LOGDIR="/srv/mrtg"

GRAPHER_BACKEND_SFLOW_ENABLED=true
GRAPHER_BACKEND_SFLOW_ROOT="http://sflow-server.example.com/grapher-sflow"

GRAPHER_BACKEND_SMOKEPING_ENABLED=true
GRAPHER_BACKEND_SMOKEPING_URL="http://smokeping-server.example.com/smokeping"
```

For those interested, the complete Grapher configuration file can be seen in [`$IXPROOT/config/grapher.php`](https://github.com/inex/IXP-Manager/blob/main/config/grapher.php). Remember: put your own local changes in `.env` rather than editing this file directly.


The global (non-backend specific) options are:

* `GRAPHER_BACKENDS` - in a typical production environment this would be `"mrtg|sflow|smokeping"` which means *try the MRTG backend first, then sflow and then smokeping*. We ship with this set as `"dummy"` so you can see sample graphs working out of the box.
* `GRAPHER_CACHE_ENABLED` - the IXP industry standard for graphing is to graph at 5min intervals. With the cache enabled, IXP Manager does not have to regenerate / reload / reprocess log / rrd / image files if we have cached them and they are less than 5mins old. This is enabled by default which is the recommended setting.

Backend specific configuration and set-up instructions can be found in their own sections below.
