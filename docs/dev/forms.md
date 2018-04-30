# Forms

This page collates various notes and bets practice for writing HTML forms with IXP Manager and Laravel.

**IXP Manager** uses the library [Former](https://github.com/formers/former) to generate forms. [Here are some examples](https://github.com/formers/former/wiki/Usage-and-Examples) of how to use Former.

## HTML5 Validation

Former adds HTML5 validation tags when it created forms. If you wish to test the PHP code's validation rules, you will need to disable this is development by setting the following `.env` setting:

```
FORMER_LIVE_VALIDATION=false
```

## Checkboxes

We had some issues using Former's checkboxes correctly - this is why we are providing the *correct* way to use them.

### Configuration

First make sure that the Former configuration file (`config/former.php`) is correctly configured:

```php
// Whether checkboxes should always be present in the POST data,
// no matter if you checked them or not
'push_checkboxes'         => true,

// The value a checkbox will have in the POST array if unchecked
'unchecked_value'         => 0,
```

### View

The following is the structure of a checkbox input:


- `Former::checkbox( 'checkbox-name' )` will be the HTML `name=""` of the input in the DOM.
- `->id( 'checkbox-id' )` will be the HTML `id=""`` of the input in the DOM, it is not required and defaults to the name above.
- `->label( 'my-label' )` will be the label of the input displayed on the *left* of the checkbox, it is not required. If you are just using a right hand side text label, setting this to `'&nbsp;'` can help improve layout.
- `->label( 'my-text' )` will be the text of the input displayed on the *right* of the checkbox, it is not required.
- `->value( 1 )` **this is really important for the correct functioning of the checkboxes**.
- `->blockHelp( "help text”)` will be the help text of the checkbox.


**Note:** in this example the checkbox will be unchecked:

```php
Former::checkbox( 'checkbox-name' )
    ->id( 'checkbox-id' )
    ->label( 'my-label' )
    ->text( 'my-text' )
    ->value( 1 )
    ->blockHelp( "Help text” );
```

To check a checkbox by default add the following function to the checkbox structure above:

```php
    ->check()
```

If the checkbox has to be checked depending on a variable:

```php
    ->check( $myVariableIsChecked ? 1 : 0 )
```

**Note:** The above case should be an exception and not a common way to populate the checkboxes. To populate the checkboxes correctly you have to do it via the controller as explained below.

### Controller

You can populate a form via the controller with the function `Former::populate()` by the usual method of passing an array of values:

```php
Former::populate([
    'my-checkbox' => $object->isChecked() ? 1 : 0,
]);
```
