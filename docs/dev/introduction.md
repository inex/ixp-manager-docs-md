# Development Introduction

We welcome contributions to IXP Manager from the community. The main requirement is that you sign the [contributor's license agreement](cla.md).

## Core vs Packages

If you plan to add a significant / large piece of functionality, then please come and talk to us first via the [mailing lists](https://www.ixpmanager.org/support). There are two ways to get such contributions into IXP Manager:

1. added to the core code with our help and guidance; or
2. as a optional package.

The following is a reply to someone looking to contribute something that didn't fit with what IXP Manager's mission was which may also help anyone considering contributing.

> We have learned the very (very) hard way to avoid adding non-core functionality into the core of IXP Manager. At INEX, we won't be using XXX in the short to medium term and nor are we aware of IX's that use it.
>
> This means that XXX code will be non-core and not used or tested (or testable easily) by the core IXP Manager developers. This creates a bunch of issues including:
>
> a) becomes a new consideration for IXP Manager updates and schema changes;
>
> b) the IXP Manager issue tracker and mailing list will be the goto place for people seeking help with this functionality and we will not be able to provide that;
>
> c) would require assurances of maintainers and support for XXX to the project - I'm not sure that can be given at this stage;
>
> d) large features require documentation: https://docs.ixpmanager.org/
>
> e) past experience has shown us that we often end up having to remove chunks of non-core functionality due to (a), (b) and (c) above and this is also costly on time.
>
> Now, we *really* do not want to discourage adding XXX support to IXP Manager - I like the project and you have shown it can work at an IX. It'd be great to have it as part of the IXP Manager tool chain.
>
> One of the advantages of switching from Zend Framework to Laravel has been the ability to have add on functionality by way of packages:
>
> https://laravel.com/docs/5.6/packages
>
> I think this is a perfect way to add XXX support and we can help ensuring UI hooks by detecting the packet and adding menu options.
>
> This also solves all the issues above:
>
> a) is not an impediment to upgrades: if the XXX package falls behind the pace of IXP Manager development and someone wants XXX support, they just install a version of IXP Manager that is aligned with the XXX package.
>
> b) issue and support wise, having XXX as a package creates a clean line of delineation between IXP Manager and XXX code bases so people can raise issues and questions with the correct project.
>
> c) is mostly answered by (a).
>
> d) documentation becomes the purview of the XXX team and we can provide the appropriate links from ours.

## Database / ORMs

Another answer to the question of Laravel Eloquent vs Doctrine ORM:

> We don't use Laravel Eloquent as the project has historically always used Doctrine ORM. It's far too much work to try and swap that out for Eloquent.
>
> That's not to say there is any issue with you using Eloquent with the following notes and provisions:
>
> a) do not change the schema of any existing table. This would need to be done in IXP Manager core via Doctrine as part of a new release and should be discussed with the core developers.
>
> b) ideally schema changes would be limited to namespaced (xxx_*) tables where xxx represents your package / feature.
