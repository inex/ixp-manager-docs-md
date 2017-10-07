# Runtime Configuration

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
