# RIR Objects

IXP Manager can generate (and email) your RIR objects - for example your AS-SETs, AS object, etc - to your RIR for automatic updates / maintenance.

As a concrete example of this, see how INEX do this with our RIPE objects as follows:

* [AS2128](https://apps.db.ripe.net/db-web-ui/#/lookup?source=ripe&key=AS2128&type=aut-num) - INEX's route collector / management ASN
* [AS43760](https://apps.db.ripe.net/db-web-ui/#/lookup?source=ripe&key=AS43760&type=aut-num) - INEX's route server ASN
* [AS-SET-INEX-CONNECTED](https://apps.db.ripe.net/db-web-ui/#/lookup?source=ripe&key=AS-SET-INEX-CONNECTED&type=as-set) - the set of ASNs/AS-SETs connected to INEX
* [AS-SET-INEX-RS](https://apps.db.ripe.net/db-web-ui/#/lookup?source=ripe&key=AS-SET-INEX-RS&type=as-set) - the set of ASNs/AS-SETs peering with INEX's route servers

Some RIRs, such as RIPE, has [a facility to update these objects by email](https://www.ripe.net/manage-ips-and-asns/db/support/documentation/ripe-database-documentation/updating-objects-in-the-ripe-database/6-4-email-updates).

## Configuration

The general form of the Artisan command is:

```sh
$ php artisan rir:generate-object --send-email      \
    --to=test-dbm@ripe.net                        \
    --from me@example.com  autnum
```

You can see the options by using the standard `-h` help switch with Artisan:

```sh
$ php artisan rir:generate-object -h
Usage:
  rir:generate-object [options] [--] <object>

Arguments:
  object                The RIR object template to use

Options:
      --send-email      Rather than printing to screen, sends and email for updating a RIR automatically
      --force           Send email even if it matches the cached version
      --to[=TO]         The email address to send the object to (if not specified then uses IXP_API_RIR_EMAIL_TO)
      --from[=FROM]     The email address from which the email is sent (if not specified, tries IXP_API_RIR_EMAIL_FROM and then defaults to IDENTITY_EMAIL)
  -h, --help            Display this help message
  -q, --quiet           Do not output any message

Help:
  This command will generate and display a RIR object (and optionally send by email)
```

You will note that without the `--send-email` switch, the command will print to standard output allowing you to consume the object and use it on another way.

**NB:** the generated object is stored in the cache when it is generated with `--send-email` for the first time. Future runs with `--send-email` will only resend the email if the generated object differs from the cached version. You can force an email to be sent with `--force`. Secondly, the cache used is a file system based cache irrespective of the `CACHE_DRIVER` `.env` settings. To wipe it, run: `artisan cache:clear file`.

The following options are available for use in the `.env` file:

```
#######################################################################################
# Options for updating RIR Objects - see https://docs.ixpmanager.org/features/rir-objects/

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
