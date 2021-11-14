# Foil

Foil is the view layer of IXP Manager.


## Undefined Variables

Foil is configured to throw an exception if a variable is undefined.

Methods to test a variable include:

```
<?= isset( $t->aaa ) ? 'b' : 'c' ?>
// c




```


Methods that **do not** work include:

```
<?= $t->aaa ?? 'c' ?>

```
