# Templates & Skinning

> Remember that v4 is a transition version of **IXP Manager** from Zend Framework / Smarty to Laravel and so much of the frontend / templating still uses v3 templates and code. As such, how to skin a page will depend on whether the template is found in `resources/views` (v4) or `application/[modules/xxx/]views` (v3). Both are covered here.

**IXP Manager** supports template/view skinning allowing users to substitute any of their own templates in place of the default ones shipped with IXP Manager.

## Skinning in Version 4+

First, set the following parameter in `.env`:

```    
VIEW_SKIN="example"
```

Skins should then be placed in the `resources/skins/example` directory (`example` should be substituted for whatever you want to call your own skin). The default templates can be found in `resources/views` directory. INEX bundles its own skinned templates in `resources/skins/inex` as an example.

Once a skin is enabled from `.env`, then any templates found in the skin directory *(using the same directory structure as found under `resouces/views`)* will take precedence over the default template file. This means you do not need to recreate / copy all the default files - just replace the ones you want.

In previous versions of **IXP Manager**, we used Smarty as the templating engine. This meant that if someone wanted to help improve **IXP Manager** then they would need to become familiar with PHP *and* Smarty. In v4 we dropped Smarty and, rather than using another compiled templating engine, we have decided to go with native PHP templates.

For this, we are using [Foil](http://www.foilphp.it/) - *Foil brings all the flexibility and power of modern template engines to native PHP templates. Write simple, clean and concise templates with nothing more than PHP.* Also, simulaneously supported are Lavael's own [Blade templates](https://laravel.com/docs/5.4/blade) which we sometimes use for simple pages.


### Example

The [graphing](grapher.md) MRTG configuration generator allows for custom configuration content at the top and bottom of the file. In order to have your custom configuration enabled, you need to skin two files.

Here's an example:

```
# position ourselves in the IXP Manager root directory
cd /path/to/ixp4

# make the skin directory
mkdir resources/skins/example

# create the full path required for the MRTG configuration files:
mkdir -p resources/skins/example/services/grapher/mrtg

# copy over the customisation files:
cp views/services/grapher/mrtg/custom-header.foil.php resources/skins/example/services/grapher/mrtg
cp views/services/grapher/mrtg/custom-footer.foil.php resources/skins/example/services/grapher/mrtg

# edit the above files as required
vi resources/skins/example/services/grapher/mrtg/custom-header.plates.php
vi resources/skins/example/services/grapher/mrtg/custom-footer.plates.php
```

Then, finally, edit `.env` and set the skin to use:

```
VIEW_SKINS="example"
```

You can of course skin any file including the non-custom MRTG files as suits your needs.


### Custom Variables / Configuration Options

When you are skinning your own templates, you may find you need to create custom configuration options for values you do not want to store directly in your own templates. For this, we have a configuration file which is excluded from Git. Initiate it via::

```    
cp config/custom.php.dist config/custom.php
```

This is [Laravel's standard configuration file format](https://laravel.com/docs/5.3/configuration) (which is an associative PHP array). You can also use Laravel's dotenv variables here too.

As an example, if you were to create a configuration option:

```php
<?php
'example' => [
    'key' => 'my own config value',
],
```

then in code this would be accessible as:

```php   
<?php
config( "custom.example.key", "default value if not set|null" )
```

where the second parameter is a default option if the requested configuration setting has not been defined (which defaults to `null`). In templates, this can be accessed the same way or rendered in the template with::

```php    
<?= config( "custom.example.key", "default" ) ?>
```

## Skinning Old Templates

This is still important as **IXP Manager** v4 still uses most of the previous templates.

To skin files found under `application/[modules/xxx/]views`, proceed as follows:

1. set a skin name in `.env`:
   ```
   VIEW_SMARTY_SKIN="myskin"
   ```

2. create a directory with a matching name: `application/views/_skins/myskin`.

Once the above `.env` option is set, then any pages in its skin directory (using the same directory structure as `application/views` will take precedence over the default template files. This means you do not need to recreate / copy all the default files - just replace the ones you want.

## Finding Templates

Usually there is one of two places to find a template:

* New pages in >=v4: `resources/views/$controller/$action`
* Old pages from <v4: `application/views/$controller/$action`

If you're skinning, then there's an extra two places:

* New pages in >=v4: `resources/skins/$skin/$controller/$action`
* Old pages from <v4: `application/views/_skins/$skin/$controller/$action`

The indicated variables above mean:

* `$controller`: typically the first part of the URL (after the main IXP Manager site) for the page you are looking at. Examples include: `patch-panel`, `router` but they may also be deeper API paths such as `api/v4/router`.
* `$action`: the last part of the URL such as `edit`.
* `$skin`: the name of your skin as defined above.

**Typically**, following the URL path in the views directory will yield the template file you need.

To help identify if the page you are looking at is from the <v4 or >=v4 code base, we have added a HTML comment to the templates which appears just after the `<head>` tag as follows:

* For >=v4 (new codebase):

    ```html
    <!--  IXP MANAGER - template directory: resources/[views|skins] -->
    ```

* For <v4 (old codebase):

    ```html
    <!--  IXP MANAGER - template directory: application/views -->
    ```
