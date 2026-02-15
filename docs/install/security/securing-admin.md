# Securing /admin URLs

The following are examples for securing `/admin` URLs as described [in the security page](../security.md#securing-administrative-functions).

???+ warning "**These are generic examples on how to protect `/admin` using common web servers. Ensure you test your final implementation to verify that it works.**"


## Apache Example

The following uses a very basic Apache virtual host configuration which works with IXP Manager. We add the new `<Location ...>` clause to restrict access to `/admin/`.



```
<VirtualHost *:443>
    ServerName portal.example.net

    ServerAdmin webmaster@localhost
    DocumentRoot /srv/ixpmanager/public

    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

    <Directory /srv/ixpmanager/public>
        Options FollowSymLinks
        AllowOverride None
        Require all granted

        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} -s [OR]
        RewriteCond %{REQUEST_FILENAME} -l [OR]
        RewriteCond %{REQUEST_FILENAME} -d
        RewriteRule ^.*$ - [NC,L]
        RewriteRule ^.*$ /index.php [NC,L]
    </Directory>

    # This clause is the new element that restricts access to /admin
    <Location "/admin/">
        <RequireAny>
            Require ip 127.0.0.1/8
            Require ip 192.0.2.0/28
            Require ip 192.0.2.128/27
            Require ip 2001:db8:0:100::/64
            Require ip 2001:db8:0:101::/64
        </RequireAny>
    </Location>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    ### SSL config
    Include /etc/letsencrypt/options-ssl-apache.conf
    SSLCertificateFile /etc/letsencrypt/live/portal.example.net/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/portal.example.net/privkey.pem

</VirtualHost>

<VirtualHost *:80>
    ServerName portal.example.net

    RewriteCond %{SERVER_NAME} =portal.example.net
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
```


## Nginx Example


```
server {
        listen 80;
        listen [::]:80;
        server_name portal.example.net;
        rewrite     ^   https://portal.example.net$request_uri? permanent;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name portal.example.net;


    ssl_certificate                 /etc/letsencrypt/live/portal.example.net/fullchain.pem;
    ssl_certificate_key             /etc/letsencrypt/live/portal.example.net/privkey.pem;

    root /srv/ixpmanager/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location /admin/ {
        allow 127.0.0.0/8;
        allow 192.0.2.0/28;
        allow 192.0.2.128/27;
        allow 2001:db8:0:100::/64;
        allow 2001:db8:0:101::/64;
        deny all;

        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        # With php7.0-fpm:
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
```


## Varnish Example

**1. Define an ACL**

```
acl adminaccess {

    # Known safe IP addresses
    "127.0.0.0/8";
    "192.0.2.0/28";
    "192.0.2.128/27";

    "2001:db8:0:100::/64";
    "2001:db8:0:101::/64";
}
```

**2. Define a function to check access against this ACL**

```
# Note that we pipe here because we do not want to cache IXP Manager.
# We also assume that https has already been enforced.
sub border_control {
    if (req.http.X-Forwarded-Proto == "https" && std.ip(req.http.X-Real-IP,"0.0.0.0") ~ adminaccess) {
        return(pipe);
    }

   return(synth(403, "Access denied [border_control]"));
}
```

**3. Secure access**

```
sub vcl_recv {

    # ....


    # assume IXP manager is served from portal.example.net:
    if (req.http.host == "portal.example.net") {

        # Do not allow crawlers access the looking glass:
        if (req.url ~ "^/lg/?" && req.http.User-Agent ~ "(?i)(googlebot|ClaudeBot|Amazonbot|DataForSeoBot|AhrefsBot|DotBot|PetalBot|bingbot|SemrushBot|msnbot|YandexBot|GPTBot|SeznamBot)" ) {
            return (synth (403, "No bot crawling please"));
        }

        # point this to your IXP Manager server
        set req.backend_hint = ixpmanager;

        # secured URLs
        if (req.url ~ "^/admin/?" ) {
            call border_control;
        }

        # otherwise:
        return(pipe);
}
```




