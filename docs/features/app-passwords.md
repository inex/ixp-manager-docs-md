# Application-Specific Passwords

Application-Specific Passwords are often just called App Passwords or Device-Specific Passwords.

In some developer or modern API contexts, they are also referred to as Personal Access Tokens (PATs), but for mail servers and end-user devices, *App Passwords* is the standard terminology used by major providers like Microsoft, Google, and Apple.

App Passwords can be used, where necessary, to bridge the gap to modern security standards where a necessary system creates a classic compliance headache, such as no direct support for Two-Factor Authentication (2FA). 

One such example is Dovecot, the world's leading email backend platform for IMAP and POP3 access. 

## What is an Application-Specific Password?

An App Password is a long, randomly generated password (usually 16 characters) that allows a specific legacy application or device—which doesn't natively support Two-Factor Authentication (2FA) or modern authentication protocols (like OAuth 2.0) - to securely access your account.

IXP Manager implements an application-specific password manager for the convenience of IXPs who need it and who do not have an alternative system. At a high-level, IXP Manager's implementation has the following features and restrictions:

* Passwords must be hashed when stored in the database - there is no plaintext option and no way to retrieve a password after initially creating it.
* It is only available for administrative users.
* The hashing options available are: bcrypt, argon, and argon2id.
* There is an option to keep a record of when passwords were used and from what IP address, but that is dependent on support from the downstream application. These are expunged after 90 days by default.
* Passwords must have an expiry date, with the default being 12 months from creation.


## How This Satisfies ISO 27001 (or other ISMS policies)

Because the system in question, e.g. a mail server, cannot natively prompt an iPhone or a laptop for a 2FA code every time it checks for mail, we shift the 2FA requirement to the issuance of the credential. This is acceptable as a control as:

1. There is an **MFA choke point**: A threat actor cannot generate a password to compromise a device without first bypassing the 2FA-protected web portal.

2. **Isolation / Reduced Blast Radius**: If a user's laptop is compromised, the attacker only gets the App Password for that specific laptop. They do not get the user's master password, and they cannot log into the web portal or other devices. The use of enforced expiration also time-bounds exposure.

3. **Audit Trail & Revocation**: You have central administrative control to log, monitor, and revoke access on a per-device basis.

## Configuration Options

<dl>

  <dt><code>IXP_FE_APP_PASSWORDS_MAX</code></dt>
  <dd>Maximum number of app passwords per used. Defaults to 50.</dd>

  <dt><code>IXP_FE_APP_PASSWORDS_DEFAULT_ALGO</code></dt>
  <dd>The default hashing algorithm to use when storing passwords. Defaults to <code>bcrypt</code>. Other options are <code>argon</code> and <code>argon2id</code></dd>.

  <dt><code>IXP_FE_APP_PASSWORDS_USER_CAN_CHANGE</code></dt>
  <dd>If set to <code>true</code> then the user case chose from the above hashing mechanisms on a per password basis. Defaults to <code>false</code>.</dd>

  <dt><code>IXP_FE_APP_PASSWORDS_HISTORY_RETENTION_DAYS</code></dt>
  <dd>How many days login history (when and from what IP address) is retained. Defaults to 90 (days). <i>Note that expired passwords will be automatically deleted 28 dates after expiration.</i>></dd>

  <dt><code>IXP_FE_APP_PASSWORDS_MAX_EXPIRES_DURATION</code></dt>
  <dd>Maximum duration for password expiry (e.g. '30 days', '12 months'). Defaults to '1 year'.</dd>

  <dt><code>IXP_FE_FRONTEND_DISABLED_APP_PASSWORD</code></dt>
  <dd>Set to <code>true</code> to disable this feature.
</dl>


## Example - Dovecot

Detailed example to follow with:

- advice on limiting database access
- how to authenticate (noting some users will have multiple username/password couples)
- how to log




