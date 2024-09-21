# Runtime Configuration

## Behind a HTTP[S] Proxy

If you are running IXP Manager behind a load balancer / proxy that terminates TLS / SSL connections, you may notice your application sometimes does not generate HTTPS links. Typically this is because your application is being forwarded traffic from your load balancer on port 80 and does not know it should generate secure links.

IXP Manager supports trusted proxies via [Laravel](https://laravel.com/docs/11.x/requests#configuring-trusted-proxies).

See the above links for complete documentation. To just get it working, you need to:

1. Publish the default trusted proxies configuration file:
    ```
    cd $IXPROOT
    ./artisan vendor:publish --provider="Fideloper\Proxy\TrustedProxyServiceProvider"
    ```

2. The above will create a file `${IXPROOT}/config/trustedproxy.php`. For the most part, you now just need to change the IP address(es) in the array `proxies` to those of your own proxy/proxies.

**NB:** as well as the above, it is also critical that your have correctly set `APP_URL` in the `.env` file for URL generation to correctly work.


## Disabling Controllers

Controllers can be disabled by setting the following config item in `config/ixp_fe.php`:

```php
<?php
[
    // ...,

    'frontend' => [
        'disabled' => [
            'xxx'   => true,
        ],
    ],
];
```

where `xxx` is the controller name. This name is in kebab-case format including any non-`IXP\Http\Controllers` namespace. Here are some controller - xxx examples:

* \IXP\Http\Controllers\InfrastructureController => infrastructure
* \IXP\Http\Controllers\CustKitController => cust-kit
* \IXP\Http\Controllers\Interfaces\PhysicalInterfaceController => interfaces-physical-interface

This action is controlled by the `IXP\Http\Middleware\ControllerEnabled` middleware.

Note that in the configuration file, we have some pre-defined dotenv settings for commonly disabled controllers. It is a bad idea to manually edit the configuration files. If you find a controller than should be disabled and there there is no dotenv option, please [open an issue](https://github.com/inex/IXP-Manager/issues).
