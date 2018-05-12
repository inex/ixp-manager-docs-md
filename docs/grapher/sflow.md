# Backend: sflow

Documentation on sflow is being prepared for v4 but the [v3 documentation is still available here](https://github.com/inex/IXP-Manager/wiki/Installing-Sflow-Support).

The previous version of IXP Manager (<4) used a script called `sflow-graph.php` which was installed on the sflow server to create graphs on demand. IXP Manager v4 does not use this but pulls the required RRD files directly.

If you have these on the same server (not typically recommended), then set the path accordingly in `.env`:

```
GRAPHER_BACKEND_SFLOW_ROOT="/srv/ixpmatrix"
```

If you have implemented this via a web server on a dedicated sflow server (as we typically do at INEX), then you need to expose the RRD data directory to IXP Manager using an Apache config such as:

```
Alias /grapher-sflow /srv/ixpmatrix

<Directory "/srv/ixpmatrix">
    Options None
    AllowOverride None
    <RequireAny>
            Require ip 192.0.2.0/24
            Require ip 2001:db8::/32
    </RequireAny>
</Directory>
```

and update `.env` for this with something like:

```
GRAPHER_BACKEND_SFLOW_ROOT="http://www.example.com/grapher-sflow"
```
