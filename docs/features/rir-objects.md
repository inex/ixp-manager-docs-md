# RIR Objects

IXP Manager can generate (and email / update RIPE via REST) your RIR objects - for example your AS-SETs, AS object, etc - to your RIR for automatic updates / maintenance.

As a concrete example of this, see how INEX do this with our RIPE objects as follows:

* [AS2128](https://apps.db.ripe.net/db-web-ui/#/lookup?source=ripe&key=AS2128&type=aut-num) - INEX's route collector / management ASN
* [AS43760](https://apps.db.ripe.net/db-web-ui/#/lookup?source=ripe&key=AS43760&type=aut-num) - INEX's route server ASN
* [AS-SET-INEX-CONNECTED](https://apps.db.ripe.net/db-web-ui/#/lookup?source=ripe&key=AS-SET-INEX-CONNECTED&type=as-set) - the set of ASNs/AS-SETs connected to INEX
* [AS-SET-INEX-RS](https://apps.db.ripe.net/db-web-ui/#/lookup?source=ripe&key=AS-SET-INEX-RS&type=as-set) - the set of ASNs/AS-SETs peering with INEX's route servers

Some RIRs have a facility to update these objects by email, but RIPE phased that out at the end of 2025.

## Configuration

The general form of the Artisan command to update via email is:

```sh
$ php artisan rir:generate-object --send-email      \
    --to=test-dbm@ripe.net                        \
    --from me@example.com  autnum
```

And to update RIPE via their REST API:

```sh
$ php artisan rir:generate-object --update-ripe-db autnum
```


You can see the options by using the standard `-h` help switch with Artisan:

```sh
$ php artisan rir:generate-object -h
Usage:
  rir:generate-object [options] [--] <object>

Arguments:
  object                The RIR object template to use

Options:
      --send-email        Rather than printing to screen, sends and email for updating a RIR automatically
      --update-ripe-db    Update the RIPE database with the generated object, using the RIPE REST API
      --force             Send email/update RIPE even if the generated object matches the cached version
      --to[=TO]           The email address to send the object to (if not specified then uses IXP_API_RIR_EMAIL_TO)
      --from[=FROM]       The email address from which the email is sent (if not specified, tries IXP_API_RIR_EMAIL_FROM and then defaults to IDENTITY_EMAIL)
      
      -h, --help          Display this help message
      -q, --quiet         Do not output any message on success

Help:
  This command will generate and display a RIR object (and optionally send by email/post to RIPE)
```

You will note that without the `--send-email/--update-ripe-db` switch, the command will print to standard output allowing you to consume the object and use it on another way.

**NB:** the generated object is stored in the cache when it is generated for the first time. Future runs will only resend the email/update RIPE if the generated object differs from the cached version. You can force an update with `--force`. Secondly, the cache used is a file system based cache irrespective of the `CACHE_DRIVER` `.env` settings. To wipe it, run: `artisan cache:clear file`.

The following options are available for use in the `.env` file:

```
#######################################################################################
# Options for updating RIR Objects - see https://docs.ixpmanager.org/features/rir-objects/

# Your RIPE API key to update RIR objects via RIPE's REST API
IXP_RIPE_API_KEY="soopersecret"

# Your RIR password to allow the updating of a RIR object by email:
IXP_API_RIR_PASSWORD=soopersecret

# Rather than specifying the destination address on the command line, you can set it here
# (useful for cronjobs and required for use with artisan schedule:run)
IXP_API_RIR_EMAIL_TO=test-dbm@ripe.net

# Rather than specifying the from address on the command line, you can set it here
# (useful for cronjobs and required for use with artisan schedule:run)
IXP_API_RIR_EMAIL_FROM=ixp@example.com
```

## Objects and Templates

There are a number of predefined objects available under `resources/views/api/v4/rir` and [skinning](skinning.md) is the recommended way to add / edit these objects.

You can copy an existing template or create a new one. For example, if you wanted a template called `my-as-set`, you would create it under `resources/skins/example/api/v4/rir/my-as-set.foil.php` and then specify it to the Artisan command as:

```sh
$ php artisan rir:generate-object my-as-set
```

The template name must be lowercase, and contain only the characters: `0-9 a-z _ -`.

### RIPE Object Type and Key

To use RIPE's REST API, you need to explicitly set the RIPE object type and key via IXP Manager-only key/value pairs in the RIPE object template:

```
IXPM-OBJECT:    aut-num
IXPM-KEY:       AS66500
```

This is already in the sample objects, and INEX's production objects in `resources/skins/inex/api/v4/rir`, so you should be able to follow those examples.

### Available Template Variables

* `$customers` - complete Doctrine2 objects of all current external trafficking customers / members. You should be able to derive everything from this. Indexed by customer ID.
* `$asns` - an associative array for the generation of an IXP AS object indexed by ASN containing elements:
  * `['asmacro']` - the member's AS macro (or the ASN if no macro);
  * `['name']` - the member's name
* `$rsclients` - an associative array for the generation of an IXP's route server AS object. See the function definition for `generateRouteServerClientDetails()` in `app/Tasks/Rir/Generator.php` for details on the array structure.

## Predefined Templates / Objects

### autnum:

You'll find a standard template for an `autnum:` object at `resources/views/api/v4/rir/autnum.foil.php`; as well as INEX's own versions under resources/skins/inex/api/v4/rir/autnum-as2128.foil.php` and `autnum-as43760.foil.php` for the IXP route collector and and route servers respectively.

Just copy one of these to your own skin directory and edit as appropriate.

### as-set: - Connected ASNs

You can create an AS-SET of connected ASNs / AS macros (see INEX's [AS-SET-INEX-CONNECTED](https://apps.db.ripe.net/db-web-ui/#/lookup?source=ripe&key=AS-SET-INEX-CONNECTED&type=as-set) as an example) via the example template `as-set-ixp-connected`.

## as-set: - Route Server ASNs

You can create an AS-SET of ASNs / AS macros connected to the route servers (see [AS-SET-INEX-RS](https://apps.db.ripe.net/db-web-ui/#/lookup?source=ripe&key=AS-SET-INEX-RS&type=as-set) as an example) via the example template `as-set-ixp-rs`.

There's also templates for v4 and v6 only versions: `as-set-ixp-rs-v4` and `as-set-ixp-rs-v6`.
