# Other Property

The IXP Manager application itself occasionally has to interact or refer to other IXP Manager
web property.

This document describes these cases, and how they can be   overrided for local development.

## ixpmanager.org

The IXP Manager.org website is used to check if an IXP's infrastructure is registered, and
also accepts requests for registration from installs.

As such it can be useful to test this code against a local deployment instead of the live server.

The base url can be overridden in your `.env` file by setting `IXP_MANAGER_DOTORG_BASE_URL`.
This configuration setting has a default of 'https://www.ixpmanager.org', but you can specify
a local address.

```
IXP_MANAGER_DOTORG_BASE_URL=http://ixp-manager-website.test
```

If you are developing inside a Vagrant VM, you can also reach servers on your host machine with
the following `/etc/hosts` entry. Using the above host as an example:

```
10.0.2.2 ixp-manager-website.test
```

A helper function is provided in IXP Manager for generating URL's for this service:

```
echo ixp_manager_website_url("/community/user-list")
// outputs: https://www.ixpmanager.org/community/user-list
```

## docs.ixpmanager.org

IXP Manager links to documentation throughout the project. The default is taken to be
`https://docs.ixpmanager.org/{DOCUMENTATION_VERSION}` where `DOCUMENTATION_VERSION` is
defined in `version.php`.

The base url can be overridden in your `.env` file by setting `IXP_FE_DOCUMENTATION_BASE_URL`.

```
IXP_FE_DOCUMENTATION_BASE_URL=https://localhost:8000
```

A helper function is provided in IXP Manager for generating URL's to documentation:

```
echo documentation_url("install/upgrading/#instructions")
// outputs: https://www.ixpmanager.org/7.3/install/upgrading/#instructions
```