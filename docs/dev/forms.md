# Form
**IXP Manager**, use the library [Former](https://github.com/formers/former) to generate the forms on Laravel. [Here](https://github.com/formers/former/wiki/Usage-and-Examples) some examples of how to use Former.

## Checkboxes
We had some issues using the Former's checkboxes correctly, that why we are providing the <b>correct</b> way to use them.

###Configuration
First make sure that the Former config file (<code>config/former.php</code>) is well configurated :


```
// Whether checkboxes should always be present in the POST data,
// no matter if you checked them or not
'push_checkboxes'         => true,

// The value a checkbox will have in the POST array if unchecked
'unchecked_value'         => 0,
```

###View side

Following the structure of the checkbox input :


- <code>Former::checkbox( 'checkbox-name' )</code> will be the html <b>name</b> of the input in the DOM.
- <code>->id( 'checkbox-id' )</code> will be the html <b>id</b> of the input in the DOM, it is not required.
- <code>->label( 'my-label' )</code> will be the label of the input displayed on the <b>left</b> of the checkbox, it is not required.
- <code>->label( 'my-text' )</code> will be the text of the input displayed on the <b>right</b> of the checkbox, it is not required.
- <code>->value( 1 )</code> is really important for a good usage of the checkboxes.
- <code>->blockHelp( "help text”)</code> will be the help text of the checkbox.


**Note :** in this example the checkbox will be unchecked.

```
Former::checkbox( 'checkbox-name' )
->id( 'checkbox-id' )
->label( 'my-label' )
->text( 'my-text' )
->value( 1 )
->blockHelp( "help text”);
```

To check a checkbox by default add the following function to the checkbox structure above :

```
->check()
```

If the checkbox has to be checked depending on a variable :

```
->check( $myVariableIsChecked ? 1 : 0)
```

**Note :** This case should be an exception and not a common way to populate the checkboxes. To populate correctly the checkboxes you have to do it via the Controller as explained below.

###Server side

You can populate a form via the Controller with the function <code>Former::populate</code>  either by the usual passing of an array of values.

```
Former::populate( [
    'my-checkbox'              => $object->isChecked() ? 1 : 0,
] );
```


