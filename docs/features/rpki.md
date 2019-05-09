# RPKI

**IXP Manager** V5 supports RPKI validation on the router configuration generated for Bird v2. The best way to fully understand RPKI with IXP Manager is to [watch our presentation](https://www.inex.ie/inex-news/shiny-new-route-servers/) from APRICOT 2019 or [read this article]( https://youtu.be/cqhJwuBaxxQ?t=1549) on INEX's website.



## RPKI Validator / Local Cache

IXP Manager uses the RPKI-RTR protocol to feed ROAs to the Bird router instances. We recommend you install two of these validators/local caches from different vendors.

Let IXP Manager know where they are by setting the following `.env` settings:

```
# IP address and port of the first RPKI local cache:
IXP_RPKI_RTR1_HOST=192.0.2.11
IXP_RPKI_RTR1_PORT=3323

# While not required, we recommend you also install a second validator:
# IXP_RPKI_RTR2_HOST=192.0.2.12
# IXP_RPKI_RTR2_PORT=3323
```

INEX has installed three local caches. As of May 2019, we would recommend Cloudflare's GoRTR and NLnetLabs Routinator 3000. We had a number of issues with the current implementation of RIPE's version (excessive disk usage, regularly crashing).

See our installation notes for these:

1. [Routinator 3000](/features/rpki/routinator.md).
2. [RIPE NCC RPKI Validator 3](/features/rpki/ripe.md).
