# Looking Glass

IXP Manager supports full looking glass features when using the Bird BGP daemon and [Birdseye](https://github.com/inex/birdseye) *(a simple secure micro service for querying Bird)*.

A fully working example of this can be seen [here on INEX's IXP Manager](https://www.inex.ie/ixp/lg).

Enabling the looking glass just requires:

1. properly configured [router(s)](routers.md).
2. *Birdseye* installed on these.
3. the API endpoint must be accessible from the server running IXP Manager and this endpoint must be set correctly in the `config/routers.php` file (along with `lg_access`). Note that the Birdseye API end points do not need to be publicly accessible - just from the IXP Manager server.
4. set the `.env` option: `IXP_FE_FRONTEND_DISABLED_LOOKING_GLASS=false`.
