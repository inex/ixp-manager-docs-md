# Helpdesk Integration

** WORK IN PROGRESS - DEVELOPMENT NOTES **

As an IXP scales, it will eventually have to replace email support via a simple alias / shared IMAP mailbox with a *proper* ticketing system. After extensive (and painful!) research, we at INEX chose [Zendesk](https://www.zendesk.com/) as the system that most matched our budget and required features (1).

While your mileage may vary on this - or you may already have something else - please note that the reference implementation for helpdesk integration on IXP Manager is Zendesk. So, if you haven't already chosen one, Zendesk will provide maximum integration with minimal pain.

> Please do not open a feature request for other helpdesk implementations as the authors cannot undertake such additional work. If you wish to have integration with another helpdesk implemented, please consider [commercial support](https://www.ixpmanager.org/commercial.php)

## Features Supported

IXP Manager currently supports:

- creation and update of customers / organisations in Zendesk
- creation and update of contacts / users in Zendesk
- finding tickets by customer / organisation

Work that is in progress includes:

- allow users to create, update and close tickets in IXP Manager
- list all tickets per organisation (for admins and users)


## Configuration

*As Zendesk is the only implementation currently, this refers only to Zendesk.*

### Zendesk

You need to enable API access to Zendesk as follows:

1. Log into your Zendesk account
2. On the bottom left, click the Admin icon
3. Under *Channels* select *API*
4. Enable the Token Access and add a token

With your Zendesk login and the token from above, edit the `.env` file in the base directory of IXP Manager and set:

```
HELPDESK_BACKEND=zendesk
HELPDESK_ZENDESK_SUBDOMAIN=ixp
HELPDESK_ZENDESK_TOKEN=yyy
HELPDESK_ZENDESK_EMAIL=john.doe@example.com
```

You can now test that your settings are correct with: **FIXME**


## Implementation Development

The helpdesk implementation in IXP Manager is designed using contracts and service providers. I.e. it is done *The Right Way (tm)*.

The reference implementation is for Zendesk but it's coded to a contract (interface) at `app/Contracts/Helpdesk.php`.

The actual Zendesk implementation can be found at: `app/Services/Helpdesk/Zendesk.php`.

The good news here is if you want another helpdesk supported, you just need to:

- create an implementation like the Zendesk one above
- update the ``switch()`` statement in `app/Providers/HelpdeskServiceProvider.php`
- open a pull request for IXP Manager and this documentation



(1) Actually, Zendesk wasn't our first ticketing system. For a number of years we used [Cerb](http://www.cerberusweb.com/) but it didn't stay current in terms of modern HTML UI/UX and it suffered from feature bloat. One requirement for our replacement was a decent API and with Zendesk's API we were able to migrate all our old tickets [using this script](https://github.com/inex/cerb5-to-zendesk).
