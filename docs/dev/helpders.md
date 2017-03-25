# Helpers

Various helpers we use within IXP Manager.

## Alerts

To show Bootstrap-styled alerts on view (Foil) templates, add them in your controllers as follows:

```php
<?php
    use IXP\Utils\View\Alert\Container as AlertContainer;
    use IXP\Utils\View\Alert\Alert;

    ...

    AlertContainer::push( '<b>Example:</b> This is a success alert!, Alert::SUCCESS );
```

where the types available are: `SUCCESS, INFO (default), DANGER, WARNING`.

To then display (all) the alerts, in your foil template add:

```php
<?= $t->alerts() ?>
```

These alerts are HTML-safe as they display the message using HTML Purifier's ''clean()''.
