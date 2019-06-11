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



## Mardown Textarea

**IXP Manager** uses the library [Mardown](https://github.com/erusev/parsedown) to edit notes input field. [Here are some examples](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) of how to use Markdown.

### View

You will have to use the following HTML structure to be able to add markdown to your textrea :

```html
<div class="form-group">
    <label for="notes" class="control-label col-lg-2 col-sm-4">Notes</label>
    <div class="col-sm-8">
        <ul class="nav nav-tabs">
            <li role="presentation" class="active">
                <a class="tab-link-body-note" href="#body">Body</a>
            </li>
            <li role="presentation">
                <a class="tab-link-preview-note" href="#preview">Preview</a>
            </li>
        </ul>
        <br>
        <div class="tab-content">
            <div role="tabpanel" class="tab-pane active" id="body">
                <textarea class="form-control" style="font-family:monospace;" rows="20" id="notes" name="notes"><?= $note_value ?></textarea>
            </div>
            <div role="tabpanel" class="tab-pane" id="preview">
                <div class="well well-preview" style="background: rgb(255,255,255);">
                    Loading...
                </div>
            </div>
        </div>
        <br><br>
    </div>
</div>
``` 
The `href="#body"` from `<a id="tab-link-body" class="tab-link-body-note" href="#body">Body</a>` have to match with the `id="body"` from `<div role="tabpanel" class="tab-pane active" id="body">`.

The same for `<a  id="tab-link-preview" class="tab-link-preview-note" href="#preview">Preview</a>` and ` <div role="tabpanel" class="tab-pane" id="preview">`.




If you want to add **more than one** textarea with markdown to your page you will have to make sure that the HTML ID of the inputs are different like on the following example :

```html

<div class="form-group">
    <label for="notes" class="control-label col-lg-2 col-sm-4">Public Notes</label>
    <div class="col-sm-8">

        <ul class="nav nav-tabs">
            <li role="presentation" class="active">
                <a class="tab-link-body-note" href="#body1">Body</a>
            </li>
            <li role="presentation">
                <a class="tab-link-preview-note" href="#preview1">Preview</a>
            </li>
        </ul>

        <br>

        <div class="tab-content">
            <div role="tabpanel" class="tab-pane active" id="body1">
                <textarea class="form-control" style="font-family:monospace;" rows="20" id="notes" name="notes"><?= $t->notes ?></textarea>
                <p class="help-block">These notes are visible (but not editable) to the member. You can use markdown here.</p>
            </div>
            <div role="tabpanel" class="tab-pane" id="preview1">
                <div class="well well-preview" style="background: rgb(255,255,255);">
                    Loading...
                </div>
            </div>
        </div>

        <br><br>
    </div>

</div>


<div class="form-group">

    <label for="private_notes" class="control-label col-lg-2 col-sm-4">Private Notes</label>
    <div class="col-sm-8">

        <ul class="nav nav-tabs">
            <li role="presentation" class="active">
                <a class="tab-link-body-note" href="#body2">Body</a>
            </li>
            <li role="presentation">
                <a class="tab-link-preview-note" href="#preview2">Preview</a>    
            </li>
        </ul>

        <br>

        <div class="tab-content">
            <div role="tabpanel" class="tab-pane active" id="body2">
                <textarea class="form-control" style="font-family:monospace;" rows="20" id="private_notes" name="private_notes"><?= $t->private_notes ?></textarea>
                <p class="help-block">These notes are <b>NOT</b> visible to the member. You can use markdown here.</p>
            </div>
            <div role="tabpanel" class="tab-pane" id="preview2">
                <div class="well well-preview" style="background: rgb(255,255,255);">
                    Loading...
                </div>
            </div>
        </div>

        <br><br>
    </div>

</div>

```

**Note:** Please **do not** change the HTML **class** of the elements!