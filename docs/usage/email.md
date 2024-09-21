# Configuring Email

**IXP Manager** uses Laravel's [mail system](https://laravel.com/docs/master/mail) to send email. This system allows for many possible email sending drivers (such as Mailgun, Postmark, Amazon SES, etc.). If you wish to use one of these services than please [refer to the official documentation](https://laravel.com/docs/master/mail). You can also read the `config/mail.php` configuration file in your **IXP Manager** installation for further details. *NB: we link to the 'master' version of Laravel's documentation above - see IXP Manager's `composer.json` file and use the appropriate version of Laravel's documentation to match.*

This guide will explain how to configure and test **IXP Manager** to send email using a standard SMTP service.

## Configuring SMTP

A sample SMTP configuration block in your **IXP Manager** `.env` file would be:

```
### Email Settings.
#
# We use Laravel's mail system - see: https://docs.ixpmanager.org/usage/email/
#
# The default setting are as follows:
#
# MAIL_MAILER="smtp"
# MAIL_HOST="localhost"
# MAIL_PORT=25
# MAIL_ENCRYPTION=false
# MAIL_USERNAME=
# MAIL_PASSWORD=
```

The options that are commented out above show defaults. Under the hood, Laravel currently uses [swiftmailer](https://swiftmailer.symfony.com/docs/sending.html) and the parameters above are passed through to that library (this changes from Laravel v9).

The configuration options for SMTP in the `.env` file are as follows.

`MAIL_MAILER="smtp"` - this is the mail transport to use. The other available options are outside the scope of this documentation.

`MAIL_HOST` is the hostname or IP address of your SMTP relay server. We would generally expect an IXP to have an internal SMTP relay server within the management network to handle the sending of email from monitoring systems, cron processes, IXP Manager, etc. This can also be `localhost` or `127.0.0.1` if you are running a local daemon such as Postfix.

`MAIL_PORT` is the TCP port which the mail relay server listens for connections. Typical values are `587` for TLS encrypted mail servers and `25` for unencrypted mail servers (these should be on your local network only - if you are using a third party or remote relay service, you should use TLS or SSL encryption).

`MAIL_ENCRYPTION` can be `"tls"` or `"ssl"` for encryption. If you are using localhost or an internal relay server without encryption, set this to `MAIL_ENCRYPTION=false`.

Finally, `MAIL_USERNAME` and `MAIL_PASSWORD` can be set if your mail relay server requires authentication. If unset, then no authentication is assumed (which is the default).

A local SMTP relay server on the same host as **IXP Manager** would therefore require no configuration as the defaults mirror:

```
MAIL_MAILER="smtp"
MAIL_HOST="localhost"
MAIL_PORT="25"
MAIL_ENCRYPTION=false
# MAIL_USERNAME=
# MAIL_PASSWORD=
```


## Sender Identity

**IXP Manager** sends emails using the name and email address configured in the following `.env` parameters:

```
IDENTITY_NAME="${IDENTITY_LEGALNAME}"
IDENTITY_EMAIL="ixp@example.com"
```

Where `${IDENTITY_LEGALNAME}` means use the value as configured in the `IDENTITY_LEGALNAME` `.env` parameter.

You should set these as appropriate to your IXP.


## Testing SMTP

An artisan SMTP test utility can be run as follows:

```sh
$ php artisan utils:smtp-mail-test [-v] {recipient-email}
```

A example of a working test run looks like this:

```
$ php artisan utils:smtp-mail-test me@example.com
This utility allows you to test your SMTP settings to verify that IXP Manager can send email.

Testing using the following parameters:

+------------+---------------------+
| Driver     | smtp                |
| Host       | localhost           |
| Port       | 25                  |
| Encryption |                     |
| Username   |                     |
| Password   |                     |
| From Name  | INEX DEV IXP        |
| From Email | test@ixpmanager.org |
+------------+---------------------+



Trying to send email...

SUCCESS - email has been sent.
```

If you add the verbose option you will also be shown the SMTP dialog:

```
$ php artisan utils:smtp-mail-test -v me@example.com

...

========================================
SMTP Dialog:

++ Starting Swift_SmtpTransport
<< 220 mail.example.com ESMTP Postfix

>> EHLO [127.0.0.1]

<< 250-mail.example.com
250-PIPELINING
250-SIZE 80200000
250-VRFY
250-ETRN
250-STARTTLS
250-ENHANCEDSTATUSCODES
250-8BITMIME
250-DSN
250 SMTPUTF8

>> STARTTLS

<< 220 2.0.0 Ready to start TLS

...
```

If there is an error sending an email, it will provide the exception thrown and the error message:

```
...
Trying to send email...

FAILED TO SEND EMAIL!



Exception thrown: ErrorException
Error: stream_socket_enable_crypto(): Peer certificate CN=`mail.example.com' did not match expected CN=`192.0.2.16'
File: /tmp/dev/ixpm/vendor/swiftmailer/swiftmailer/lib/classes/Swift/Transport/StreamBuffer.php
Line: 94
```

Similarly, if you provide the verbose option in the case of an error, you will be provided with a stack trace and the SMTP dialog.
