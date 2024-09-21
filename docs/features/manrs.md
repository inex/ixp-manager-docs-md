# MANRS

[MANRS](https://www.manrs.org/) - *Mutually Agreed Norms for Routing Security* - is a global initiative, supported by the Internet Society, that provides crucial fixes to reduce the most common routing threats. ﻿

IXP Manager rewards networks that have joined the MANRS program by highlighting this on the customer's public and internal pages - for example:

![MANRS Example](img/manrs-google.png)

This information is updated daily via the [task scheduler](cronjobs.md). If you want to run it manually, run this Artisan command:

```sh
$ php artisan ixp-manager:update-in-manrs -vv
MANRS membership updated - before/after/missing: 5/5/104
```

As you'll see from the output, it will show you the results. We will provide more tooling within IXP Manager to show this information in time.
