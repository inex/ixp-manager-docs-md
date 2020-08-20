# Looking Glass

**IXP Manager** has [looking glass support](../features/looking-glass.md) allowing IXPs to expose details on route server / collector / AS112 BGP sessions to their members.

As it stands, we have only implemented one looking glass backend - [Bird's Eye](https://github.com/inex/birdseye); a *simple secure micro service for querying Bird (JSON API)* (and also written by us, INEX).

We have implemented this in **IXP Manager** as a service so that other backends can be added easily.

*Disclaimer: the links and line numbers here are against IXP Manager [v4.5.0](https://github.com/inex/IXP-Manager/tree/v4.5.0) and they may have changed since.*

## Adding Support for Additional LGs

1. An additional API backend needs to be given a constant in [Entities\Router](https://github.com/inex/IXP-Manager/blob/master/database/Entities/Router.php#L90) named `API_TYPE_XXX` where `XXX` is an appropriate name.

2. It then needs to have a `case:` check in [app/Services/LookingGlass.php](https://github.com/inex/IXP-Manager/blob/v4.5.0/app/Services/LookingGlass.php#L52). This needs to instantiate your service provider.

3. Your service provider must implement the [App\Contracts\LookingGlass](https://github.com/inex/IXP-Manager/blob/v4.5.0/app/Contracts/LookingGlass.php) interface.

For a concrete example, see the [Bird's Eye implementation](https://github.com/inex/IXP-Manager/blob/v4.5.0/app/Services/LookingGlass/BirdsEye.php).
