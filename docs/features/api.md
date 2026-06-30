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

Note also that:

1. When you create an API key, it will be displayed on screen. This is the last time you will be able to view it in IXP Manager in plaintext as it is hashed via SHA-256 in the database.
2. API keys must have an expiry data, with the maximum being 12 months.
3. Reminder emails are sent at 14-days from expiry to the user. Having a descriptive description on where the API key is in use would be helpful to you.
4. Expired API keys are deleted from the database after 28-days.


## Format of API Keys

From v7.3.0 onwards, API keys have the following format:

```
   ixpm_ident1234567_sec87654321098765432109876543210crc321
   └──┘ └──────────┘ └──────────────────────────────┘└────┘
 Prefix  Identifier               Secret            Checksum
 (4 ch)   (12 ch)                 (32 ch)            (6 ch)
```

1. The prefix for IXP Manager's keys will always be `ixpm_` to help identify them as such.
2. The 12-character identifier is the only part of the key that is retained in IXP Manager's database and displayed to the user. This will allow you to match your keys in use to their entry in IXP Manager. This is also used to look up the key in the database (O(1)) when presented.
3. The secret is a cryptographically secure random string that ensures authenticity.
4. A small block of characters appended to the end, calculated from the rest of the key, and verified before database lookup.

By default, a user can create no more than 10 keys. If you wish to change this, set `IXP_FE_API_KEYS_MAX=n` in `.env` where `n` is an integer value > 0.

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
curl -X GET -H "X-IXP-Manager-API-Key: ixpm_ident1234567_sec87654321098765432109876543210crc321" https://ixp.example.com/api/v4/test
```

### 2. As a URL Parameter

This is a legacy method that is now being deprecated. You may tack your key on as follows:

```
https://ixp.example.com/api/v4/test?apikey=ixpm_ident1234567_sec87654321098765432109876543210crc321
```

As of 7.3, this feature is still enabled, but IXP Manager will write notices to the log file informing you of the deprecated usage. You can be disable support for API Keys in URLs by  setting `IXP_ALLOW_DEPRECATED_APIKEYS_VIA_GET=false` in `.env`.

The log message will contain the API Key ID for legacy API Keys, or the API Token Identifier for new API keys.

A future release will turn the setting off by default and software using this authorization method will be denied. It can be enabled by setting `IXP_ALLOW_DEPRECATED_APIKEYS_VIA_GET=true` in `.env`.  A subsequent release will remove support for this feature entirely.

## API Key Management

* You can add an optional description to an API key. This allows you to record what the key is used for, or where it is used.
* Expiration dates are now mandatory for API keys. The key may be used *up to* that date but not on the date. The expiration date cannot be changed after the key is created.
* A reminder email will be sent to the API key owner 14 days before expiration takes place. This is to give notice of expiration, and give you time to rotate API keys to prevent downtime of dependent services.
* Expired API keys are automatically deleted after 28 days ([via the scheduler](cronjobs.md)).

As of v7.3 it is no longer possible to be shown the full API key after it is created.

Additionally, the expiration date is limited to 1 year into the future by default. To change this, set `IXP_FE_API_KEYS_MAX_EXPIRES_DURATION` to a custom duration (for example, "6 months" "2 years") as required. The restriction exists to encourage credential rotation - extending the duration is not recommended.

By default, a user can create no more than 10 keys. If you wish to change this, set `IXP_FE_API_KEYS_MAX=n` in `.env` where `n` is an integer value > 0.
