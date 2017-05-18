# API

**IXP Manager** has a number of API endpoints which are documented in the appropriate places throughout the documentation.

Please find details below about authenticating for API access to secured functions.


## Creating an API Key

When logged into **IXP Manager**, create an API as follows:

1. Select *My Account* on the right hand side of the top menu.
2. Select *API Keys* from the *My Account* menu.
3. Click the plus / addition icon on the top right of the resultant *API Keys* page.

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
