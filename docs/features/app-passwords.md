# Application-Specific Passwords

Application-Specific Passwords are often just called App Passwords or Device-Specific Passwords.

In some developer or modern API contexts, they are also referred to as Personal Access Tokens (PATs), but for mail servers and end-user devices, *App Passwords* is the standard terminology used by major providers like Microsoft, Google, and Apple.

App Passwords can be used, where necessary, to bridge the gap to modern security standards where a necessary system creates a classic compliance headache, such as no direct support for Two-Factor Authentication (2FA). 

One such example is Dovecot, the world's leading email backend platform for IMAP and POP3 access. 

## What is an Application-Specific Password?

An App Password is a long, randomly generated password (usually 16 characters) that allows a specific legacy application or device - which doesn't natively support Two-Factor Authentication (2FA) or modern authentication protocols (like OAuth 2.0) - to securely access your account.

IXP Manager implements an application-specific password manager for the convenience of IXPs who need it and who do not have an alternative system. At a high-level, IXP Manager's implementation has the following features and restrictions:

* Passwords must be hashed when stored in the database - there is no plaintext option and no way to retrieve a password after initially creating it.
* It is only available for administrative users.
* The hashing options available are: sha256 (salted), bcrypt, argon, and argon2id.
* There is an option to keep a record of when passwords were used and from what IP address, but that is dependent on support from the downstream application. These are expunged after 90 days by default.
* Passwords must have an expiry date, with the default being 12 months from creation.
* A notification of expiring passwords will be sent to the user 14-days from expiry.


## How This Satisfies ISO 27001 (or other ISMS policies)

Because the system in question, e.g. a mail server, cannot natively prompt an iPhone or a laptop for a 2FA code every time it checks for mail, we shift the 2FA requirement to the issuance of the credential. This is acceptable as a control as:

1. There is an **MFA choke point**: A threat actor cannot generate a password to compromise a device without first bypassing the 2FA-protected web portal.

2. **Isolation / Reduced Blast Radius**: If a user's laptop is compromised, the attacker only gets the App Password for that specific laptop. They do not get the user's master password, and they cannot log into the web portal or other devices. The use of enforced expiration also time-bounds exposure in the event of non-detection.

3. **Audit Trail & Revocation**: You have central administrative control to log, monitor, and revoke access on a per-device basis.



## Configuration Options

<dl>

  <dt><code>IXP_FE_APP_PASSWORDS_MAX</code></dt>
  <dd>Maximum number of app passwords per user. Defaults to 50.</dd>

  <dt><code>IXP_FE_APP_PASSWORDS_DEFAULT_ALGO</code></dt>
  <dd>The default hashing algorithm to use when storing passwords. Defaults to <code>bcrypt</code>. Other options are <code>sha256</code>, <code>argon</code> and <code>argon2id</code></dd>.

  <dt><code>IXP_FE_APP_PASSWORDS_USER_CAN_CHANGE</code></dt>
  <dd>If set to <code>true</code> then the user case chose from the above hashing mechanisms on a per password basis. Defaults to <code>false</code>.</dd>

  <dt><code>IXP_FE_APP_PASSWORDS_HISTORY_RETENTION_DAYS</code></dt>
  <dd>How many days login history (when and from what IP address) is retained. Defaults to 90 (days). <i>Note that expired passwords will be automatically deleted 28 dates after expiration.</i>></dd>

  <dt><code>IXP_FE_APP_PASSWORDS_MAX_EXPIRES_DURATION</code></dt>
  <dd>Maximum duration for password expiry (e.g. '30 days', '12 months'). Defaults to '1 year'.</dd>

  <dt><code>IXP_FE_FRONTEND_DISABLED_APP_PASSWORD</code></dt>
  <dd>Set to <code>true</code> to disable this feature.
</dl>


## Offloading Verification to the Database

In some scenarios you may need to offload password verification to the database. Dovecot is one example here where Dovecot cannot evaluate multiple passwords returned for a username, which negates per-device verification.

As MySQL does not support bcrypt natively inside standard SQL functions, we need to use the salted SHA2-256 hashing method.

When using the database verification method, consider the following additional security measures:

1. Avoid plaintext leaks via log exposure (i.e., the General Query Log or Slow Query Log). If these need to be enabled, even temporarily for debugging, strictly restrict read access to /var/log/mysql/ or wherever your database system stores logs.
2. Bcrypt is intentionally designed to be slow and resource-heavy to prevent attackers from guessing passwords quickly. SHA-2 (SHA-256 or SHA-512), on the other hand, is built for speed. As such, ensure you use rate-limiting at the application level and/or tools like Fail2ban.
3. IXP Manager enforces mandatory per-password salting in its implementation, and this cannot be disabled. This avoids rainbow table vulnerabilities.
4. Consider packet sniffing between the database and the application and use TLS encryption. 


## Example - Dovecot

Some IXPs have historically used their IXP Manager user database as a single sign-on resource for other systems. As explained above, this is not compatible with modern ISMS security standards. 

An example of how this used to work would be the following Dovecot SQL definition:

```mysql
password_query = SELECT u.username AS user, \
    CONCAT( REPLACE( SUBSTRING( u.password, 1, 4 ), '$2y$', '$2a$' ), SUBSTRING( u.password, 5 ) ) as password \
    FROM user AS u INNER JOIN customer_to_users as cu ON cu.user_id = u.id \
    WHERE u.username = '%n' AND u.disabled = 0 AND cu.customer_id = XXX AND cu.privs = 3
```

When reviewing this query, and also below, note the following:

* Dovecot's MySQL credentials should be limited to SELECT on that table.
* IXP Manager's passwords are stored as Bcrypt hashes. PHP uses `$2y$` to identify these hashes where as BSD/Linux systems use `$2a$`.
* We are limited authentication to administrative users (`cu.privs = 3`) of the the IXP's own internal customer on IXP Manager (`cu.customer_id = XXX`).
* Password verification is done by Dovecot against the returned Bcrypt hash.
* Dovecot automatically escapes variables like %{password} and %n before executing SQL queries to prevent SQL injection. Ensure you never disable Dovecot's automatic escaping or attempt to manually concatenate unverified data in complex stored procedures.

As mentioned above, MySQL does not support bcrypt natively inside standard SQL functions, and so we need to use the salted SHA2-256 hashing method.

You may wish to allow the "old way", using the password in the users table, and the new way, application-specific passwords, in tandem during a transition period. This can be achieved with:

```mysql
password_query = SELECT user, password, nopassword FROM ( \
    SELECT u.username AS user, NULL AS password, 'Y' AS nopassword, 1 AS priority \
    FROM app_passwords a \
        INNER JOIN user u ON a.user_id = u.id \
        INNER JOIN customer_to_users as cu ON cu.user_id = a.user_id \
    WHERE u.username = '%n' \
      AND u.disabled = 0 \
      AND cu.custid = XXX \
      AND cu.privs = 3 \
      AND a.password = SHA2(CONCAT('%{password}', a.salt), 256) \
    UNION ALL \
    SELECT username AS user, CONCAT(REPLACE(SUBSTRING(password,1,4),'$2y$','$2a$'), SUBSTRING(password,5)) AS password, NULL AS nopassword, 2 AS priority \
    FROM user \
    WHERE username = '%n' \
      AND disabled = 0 \
      AND custid = XXX \
) AS auth_bridge \
ORDER BY priority ASC LIMIT 1
```


Detailed example to follow with:

- advice on limiting database access
- how to authenticate (noting some users will have multiple username/password couples)
- how to log



# For Dovecot 2.3+ / 3.x (uses %{user} and %{password})
password_query = SELECT NULL AS password, 'Y' AS nopassword, username AS user \
                 FROM user_passwords \
                 WHERE username = '%{user}' \
                   AND password_hash = CRYPT('%{password}', password_hash)

# For older Dovecot 2.2 systems, use %u and %w:
# password_query = SELECT NULL AS password, 'Y' AS nopassword, username AS user FROM user_passwords WHERE username = '%u' AND password_hash = CRYPT('%w', password_hash)

If you just want to track login timestamps and IP addresses, Dovecot has a lightweight, built-in plugin specifically for that. If you need to perform complex or custom database logic, you can use Dovecot's external post-login hook system.  
Method 1: The Native last-login Plugin (Recommended for Tracking)

If your database insert is primarily meant to track when a user last logged in, what protocol they used (IMAP/POP3), and their IP address, you should use the native last-login plugin. It hooks directly into Dovecot's dictionary system, making it incredibly fast and safe.
1. Enable the plugin in your Dovecot configuration:
Ini, TOML

protocol imap {
  mail_plugins = $mail_plugins last_login
}
protocol pop3 {
  mail_plugins = $mail_plugins last_login
}

plugin {
  last_login_dict = proxy::sql
  last_login_key = last-login/%{service}/%{user}/%{remote_ip}
}

dict {
  sql = mysql:/etc/dovecot/dovecot-dict-sql.conf.ext
}

2. Map it to your database in dovecot-dict-sql.conf.ext:
Ini, TOML

connect = host=localhost dbname=mail_db user=dovecot password=password

map {
  pattern = shared/last-login/$service/$user/$remote_ip
  table = user_logins
  value_field = last_access
  value_type = uint
  fields {
    username = $user
    protocol = $service
    ip_address = $remote_ip
  }
}

Whenever a user logs in, Dovecot will automatically handle the INSERT ... ON DUPLICATE KEY UPDATE or equivalent SQL behavior under the hood.