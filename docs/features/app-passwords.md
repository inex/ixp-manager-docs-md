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

### MySQL Permissions

Create a specific MySQL user for this purpose, and limit its access:

```mysql
CREATE USER `dovecot`@`192.0.2.10` IDENTIFIED BY 'random-password';
GRANT SELECT ON `ixpmanager`.`customer_to_users` TO 'dovecot'@'192.168.0.10';
GRANT SELECT ON `ixpmanager`.`user`              TO 'dovecot'@'192.168.0.10';
GRANT SELECT ON `ixpmanager`.`app_passwords`     TO 'dovecot'@'192.168.0.10';
```

### Transitioning from User Passwords to Application-Specific Keys

You may wish to allow the "old way", using the password in the users table, and the new way, application-specific passwords, in tandem during a transition period. This can be achieved with:

```mysql
password_query = SELECT user, password, nopassword, userdb_app_password_id FROM ( \
    SELECT u.username AS user, NULL AS password, 'Y' AS nopassword, 1 AS priority, a.id AS userdb_app_password_id \
    FROM app_passwords a \
        INNER JOIN user u ON a.user_id = u.id \
        INNER JOIN customer_to_users as cu ON cu.user_id = a.user_id \
    WHERE u.username = '%n' \
      AND u.disabled = 0 \
      AND cu.custid = XXX \
      AND cu.privs = 3 \
      AND a.password = SHA2(CONCAT('%{password}', a.salt), 256) \
    UNION ALL \
    SELECT username AS user, CONCAT(REPLACE(SUBSTRING(password,1,4),'$2y$','$2a$'), SUBSTRING(password,5)) AS password, \
        NULL AS nopassword, 2 AS priority, NULL AS userdb_app_password_id \
    FROM user AS u INNER JOIN customer_to_users as cu ON cu.user_id = u.id \
    WHERE u.username = '%n' AND u.disabled = 0 AND cu.customer_id = XXX AND cu.privs = 3 \
) AS auth_bridge \
ORDER BY priority ASC LIMIT 1
```

This query will return a single result (which Dovecot only supports), prioritising application-specific passwords.


### Switching to Application-Specific Keys Only

Following a transition period, you can simplify the MySQL definition to something like:

```mysql
password_query = SELECT u.username AS user, NULL AS password, 'Y' AS nopassword, a.id AS userdb_app_password_id \
    FROM app_passwords a \
        INNER JOIN user u ON a.user_id = u.id \
        INNER JOIN customer_to_users as cu ON cu.user_id = a.user_id \
    WHERE u.username = '%n' \
      AND u.disabled = 0 \
      AND cu.custid = XXX \
      AND cu.privs = 3 \
      AND a.password = SHA2(CONCAT('%{password}', a.salt), 256) \
  LIMIT 1
```

### Logging Authentication

You will need to increase your database grants for this to work:

```mysql
GRANT INSERT ON `ixpmanager`.`app_passwords_last_logins` TO 'dovecot'@'192.0.2.10';
```

There is a trigger on `app_passwords_last_logins` to update the `last_seen_at` and `last_seen_from` fields of `app_passwords`, and this way the Dovecot user does not need to be given write access to the primary `app_passwords` table.


Dovecot has [post-login scripting documentation here](https://doc.dovecot.org/2.3/admin_manual/post_login_scripting/). 

Essentially, you want the IMAP and POP3 elements of your `etc/dovecot/conf.d/10-master.conf` to look like:

```
service imap {
  executable = imap imap-postlogin
}

service pop3 {
  executable = pop3 pop3-postlogin
}

service imap-postlogin {
  executable = script-login /usr/local/sbin/dovecot-postlogin.sh
  user = root
  unix_listener imap-postlogin {
  }
}

service pop3-postlogin {
  executable = script-login /usr/local/sbin/dovecot-postlogin.sh
  user = root
  unix_listener pop3-postlogin {
  }
}
```

You want to create a database options file for running the `mysql` command:

```bash
cat >etc/dovecot/db-postauth.cnf <<END_CNF
[client]
user="dovecot"
password="random-password"
END_CNF

chown root: etc/dovecot/db-postauth.cnf
chmod a-rwx etc/dovecot/db-postauth.cnf
```

And then create the post-auth script:

```bash 
cat >/usr/local/sbin/dovecot-postlogin.sh <<END_SH
#!/bin/sh

# Capture the app password ID field passed from Dovecot
APP_PASS_ID="${APP_PASSWORD_ID}"

if [ -n "$APP_PASS_ID" ] && [ "$APP_PASS_ID" -gt 0 ]; then

    mysql --defaults-file=etc/dovecot/db-postauth.cnf -h dbhost.example.com ixpmanager  <<END_SQL
INSERT INTO app_passwords_last_logins (app_password_id, last_seen_at, last_seen_from) VALUES ('$APP_PASS_ID', NOW(), '$IP');
END_SQL

fi

# CRITICAL: Resume standard IMAP/POP3 engine execution
exec "$@"
END_SH

chown root: /usr/local/sbin/dovecot-postlogin.sh
chmod o-rwx /usr/local/sbin/dovecot-postlogin.sh
chmod ug+x /usr/local/sbin/dovecot-postlogin.sh
```


