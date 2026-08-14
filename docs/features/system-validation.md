# System Validation

IXP Manager v7.4 introduced the System Validation utility, the purpose of which is to detect common issues with the
installation or environment, report software versions, and also highlight key features in the running of an IXP.

## Usage

The validation suite can be run via either the command line or web interface. While both methods can run the same
suite of validations there are some differences between them.

The [web interface](system-validation.md#web-interface) is offers a richer experience with links to feature
documentation, links to the [Settings UI for configuration](settings.md), or direct links to the resource where a problem is
detected.

The [command line interface](system-validation.md#command-line-interface) lacks these enhancements, but performs some
additional systems checks which may be used to investigate why your IXP Manager instance is failing to run at all.

You should use the web interface unless you are investigating deeper problems in your installation.

### Command Line Interface

The command line validation is a simple PHP script, which begins by performing basic systems checks. If these succeed,
the script will then run the validation suite.

It is important to run the validation tool as same user which runs IXP Manager (most likely this is `www-data`) to
obtain accurate results - tests of write permissions, and so on, are particular to the user account which runs IXP
Manager. The tests should not be run as root.

```
cd $IXPROOT
sudo -u $MY_WWW_USER php ./validate.php
```

The basic systems check can produce warnings or errors. If an error is encountered, the suite of regular validations
will not be run - these errors should be fixed first. Anything reported in this phase will likely render your
IXP Manager web application inaccessible.

By default, only results with severity level `suggest` or higher are displayed. This minimum severity level can be
controlled by setting the `--log-level=` flag. For example, to see more verbose output:

```
sudo -u $MY_WWW_USER php ./validate.php --log-level=info
```

#### Example Output: system checks failed

```
root@vagrant:/srv/ixpmanager# sudo -u $MY_WWW_USER php ./validate.php
Software Versions:
PHP: 8.4.24
IXP-Manager: 7.3.1

Results:
task: MySQL
 * ERROR: Connection failed: SQLSTATE[HY000] [1045] Access denied for user 'ixp'@'localhost' (using password: YES)

task: Laravel Storage Directories
 * ERROR: Missing file write permission in these storage directories: storage/
 * ERROR: Missing directory write permission in these storage directories: storage/

There were errors during the validation process. Please review the checks above for details.
```

#### Example Output: validations run

```
root@vagrant:/srv/ixpmanager# sudo -u $MY_WWW_USER php ./validate.php
No errors detected during basic validations
+-------------+-------------------------------------------+
| Software    | Version                                   |
+-------------+-------------------------------------------+
| PHP         | 8.4.24                                    |
| PDO MySQL   | 8.4.24                                    |
| MySQL       | 8.0.46-0ubuntu0.24.04.3                   |
| DB Schema   | 2026_07_15_121559_add_task_last_run_table |
| IXP Manager | 7.3.1                                     |
+-------------+-------------------------------------------+
+---------------------+------------+-------------- System Validation -------------------------------------------------+
| Validator           | Result     | Message                                                                          |
+---------------------+------------+----------------------------------------------------------------------------------+
| Basic validations   | Error      | URGENT: Found composer packages installed due to `dev_requirement`. This is a    |
|                     |            | security risk on a production system. Please check the documentation for         |
|                     |            | instructions on installing libraries from composer.                              |
|                     | Warning    | APP_DEBUG is enabled                                                             |
|                     | Warning    | APP_ENV is not set to production                                                 |
|---------------------------------------------------------------------------------------------------------------------|
| IXP Manager version |            | No results reached the log-level threshold                                       |
| check               |            |                                                                                  |
|---------------------------------------------------------------------------------------------------------------------|
| Security settings   | Error      | Passing API Keys as a GET parameter is enabled - this is strongly discouraged,   |
|                     |            | and support for this will be removed in a future release. Update any dependent   |
|                     |            | software and disable this ASAP.                                                  |
|                     | Warning    | Failed to load IXP Manager login page for HTTP check. This is to be expected in  |
|                     |            | some configurations.                                                             |
|---------------------------------------------------------------------------------------------------------------------|
| Nagios monitoring   | Suggestion | Did you know IXP-Manager can generate nagios configuration to monitor your       |
| validator           |            | customers VLAN interfaces?                                                       |
           ... output trimmed ...
|---------------------------------------------------------------------------------------------------------------------|
| AS112 validator     |            | The validator did not report any results                                         |
+---------------------+------------+----------------------------------------------------------------------------------+

Log level: suggest
Validations summary: info: 20, suggest: 7, warning: 4, error: 4.
```

### Web interface

Within IXP Manager, the Validation UI is controlled by the `IXP_FE_FRONTEND_DISABLED_VALIDATION` setting which is
active by default. When this is enabled, a link to the System Validation is shown in the administrator left menu.

When you click this link, you'll see a `Run Validations` button, which when clicked will redirect you to a results
page which will auto-update as validation results are reported.

Each validation report is stored using the `file` cache driver for approximately 20 minutes. The results page has
a unique identifier for your test run. Multiple users can run validations at the same time.

On the test results page there are buttons for each severity level, allowing you to filter out results by their
severity level.

The web validation UI contains more information than the CLI report:

  - Where possible, a link is provided that takes you to the documentation for this feature, for the IXP Manager version
    you have installed.
  - If a result refers to a setting that is managed via the [Settings UI](settings.md), a link will be provided to
    the relevant settings page, or in some cases, directly to the field in question.
  - In some cases, a test-specific 'call to action' link may be associated with a validation.
  - Some validations will have additional information associated with them. These are indicated by a caret symbol &vee;.
    You can click the validation to expand and show it's additional information. This might consist of lists of test
    subjects, or links to webpages in your IXP Manager which need your attention.

## Validator lifecycle

When the validation suite is run, each validation task is started in it's own thread in the background. They
perform their checks and report their findings back to you.

Validation results consist of a message, and a severity level. In ascending order of severity these are `debug`, `info`,
`suggest`, `warning`, and `error`. Both the CLI and Web interface support filtering of results based on this severity
level. When your log level is such that all messages are filtered, the CLI will report `No results reached the log-level
threshold`, whereas the web interface will hide the validator entirely.

A validator may not find anything worth reporting. This depends on the results of the tests performed. If it happens,
the command line or web interface will report that no results were reported.

If an unhandled exception occurs, this will be highlighted and shown to you. In the command line, all failures
are displayed after the validation results table. A validator which encounters a failure may still have reported
results before the failure arose. In the web interface, a red failure icon will appear, and a failed test will never
be omitted due to the severity level.

Validators are also monitored for their run time. By default, this is 20 seconds and it would be unusual for
a validator to run for longer than this! If this arises, the task is terminated, and no results will be reported.
In the web interface, an orange icon will indicate a timed out test, and a timed out test will never by omitted
due to the chosen severity level.

## GitHub Issue Support Tool

As part of the validation CLI tool, we also provide a way to quickly generate a GitHub Issue template
with the information about your system, configuration, and IXP Manager version already completed.

`php validate.php --github-issue`

While we have developed this tool to filter out fields which may be sensitive, please make sure you
are happy that nothing sensitive has been included when copying its output.

Before opening an issue, please read this page about [Support for IXP Manager](https://www.ixpmanager.org)
to see if a GitHub issue is actually a suitable place to ask for help.

## Recurring task tracking

There are several validations in IXP Manager which check to see if a normally recurring task has run recently.

An example of such a feature is the [Nagios](nagios.md) configuration generation endpoints. These record the last
time configuration was generated, and the parameters used for generation. The system validator tool will include
an error if the last time was over 24 hours ago.

If you had been using Nagios configuration generation, but no longer do so, you will need to reset task tracking
history to make these errors go away. To reset this task history, you can do so with the following command:

```
cd $IXPROOT
php ./artisan utils:clear-task-history
```

This will remove **all** information about recent runs, giving you a clean state to start from.