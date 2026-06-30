# API

**IXP Manager** has a number of API endpoints which are documented in the appropriate places throughout the documentation.

Please find details below about authenticating for API access to secured functions.


## Creating an API Key

When logged into **IXP Manager**, create an API as follows:

1. Select *My Account* on the right hand side of the top menu.
2. Select *API Keys* from the *My Account* menu.
3. Click the plus / addition icon on the top right of the resultant *API Keys* page.
4. Select an expiration date (this is mandatory).
5. A description may be optionally provided so you can recognize what the key is for later.

**Treat your API key as a password and do not copy the below URLs into public websites and other public forums.**


## API Authentication

There are two ways to use your API key to authenticate to IXP Manager.

You can test these using the API test endpoint at `api/v4/test`. For example:

```
https://ixp.example.com/api/v4/test
```

The plaintext response will also indicate if you are authenticated or not (which can be via existing session or API key).

### 1. HTTP Header Parameter

You can pass your API key in the HTTP request as a request header parameter called `X-IXP-Manager-API-Key`. For example:

```sh
curl -X GET -H "X-IXP-Manager-API-Key: my-api-key" https://ixp.example.com/api/v4/test
```

### 2. As a URL Parameter

This is a legacy method that is still supported. You can tack your key on as follows:

```
https://ixp.example.com/api/v4/test?apikey=my-api-key
```

## API Key Management

* You can add an optional description to an API key. This allows you to record what the key is used for, or where it is used.
* Expiration dates are now mandatory for API keys. The key may be used *up to* that date but not on the date. The expiration date cannot be changed after the key is created.
* A reminder email will be sent to the API key owner 14 days before expiration takes place. This is to give notice of expiration, and give you time to rotate API keys to prevent downtime of dependent services.
* Expired API keys are automatically deleted after 28 days ([via the scheduler](cronjobs.md)).

As of v7.3 it is no longer possible to be shown the full API key after it is created.

Additionally, the expiration date is limited to 1 year into the future by default. To change this, set `IXP_FE_API_KEYS_MAX_EXPIRES_DURATION` to a custom duration (for example, "6 months" "2 years") as required. The restriction exists to encourage credential rotation - extending the duration is not recommended.

By default, a user can create no more than 10 keys. If you wish to change this, set `IXP_FE_API_KEYS_MAX=n` in `.env` where `n` is an integer value > 0.
