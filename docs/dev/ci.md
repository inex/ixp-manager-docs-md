# Continuous Integration

IXP Manager grew out of a code base and schema that started in the early '90s. Long before [test driven development](http://phpunit.de/) or [behaviour driven development](http://behat.org/) was fashionable for PHP. However, as IXP Manager is taking over more and more critical configuration tasks, we continue to back fill automated testing with continuous integration.

We use [GitHub Actions](https://github.com/features/actions) for continuous integration which is provided free for public repositories.

Our current build status is: [![Build Status](https://github.com/inex/IXP-Manager/actions/workflows/ci-ex-dusk.yml/badge.svg)](https://github.com/inex/IXP-Manager/actions)

The CI system runs the full suite of tests every time a commit is pushed to GitHub. As such, any *build failing* states are usually transitory. **Official IXP Manager releases are only made when all tests pass.**

We use two types of unit tests:

1. [PHP Unit](http://phpunit.de/) for standard unit tests;
2. [Laravel Dusk](https://laravel.com/docs/5.6/dusk) for browser based tests.

We also use [Psalm](https://psalm.dev/) for static code analysis.

The following are basic instructions on how to set up tests and an overview (or links) to some of the tests we have implemented.

**DISCLAIMER:** This is not a tutorial on unit testing, phpunit, Laravel Dusk, Psalm or anything else. If you have no experience with these tools, please read up on them elsewhere first.


## Setting Up PHPUnit Tests

Documentation by real example can be found via the [GitHub Actions workflow files](https://github.com/inex/IXP-Manager/tree/main/.github/workflows) and [the CI data directory](https://github.com/inex/IXP-Manager/tree/main/data/ci) which contains scripts, database dumps and configurations.

Testing assumes *a known good sample database* which contains a small mix of customers with different configuration options. The files generated from this database are tested against [known good](https://github.com/inex/IXP-Manager/tree/main/data/ci/known-good) configuration files. You first need to create a database, add a database user, import this testing database and then configure a `.env` file for testing (see [the one here use here](https://github.com/inex/IXP-Manager/blob/main/.env.ci)).

In MySQL:

```mysql
CREATE DATABASE ixp_ci CHARACTER SET = 'utf8mb4' COLLATE = 'utf8mb4_unicode_ci';
GRANT ALL ON `ixp_ci`.* TO `ixp_ci`@`localhost` IDENTIFIED BY 'somepassword';
FLUSH PRIVILEGES;
```

Then import the sample database:

```sh
cat data/ci/ci_test_db.sql  | mysql -h localhost -u ixp_ci -psomepassword ixp_ci
```

Now, create your `.env` for testing, such as:

```ini
DB_HOST=localhost
DB_DATABASE=ixp_ci
DB_USERNAME=ixp_ci
DB_PASSWORD=somepassword
```

Note that the [`phpunit.xml`](https://github.com/inex/IXP-Manager/blob/main/phpunit.xml) file in the root directory has some default settings matching the test database. You should not need to edit these.

## Setting Up Laravel Dusk

Please review the [official documentation here](https://laravel.com/docs/main/dusk).

You need to ensure the development packages for IXP Manager are installed via:

```sh
# move to the root directory of IXP Manager
cd $IXPROOT
composer install --dev

# install Chromium:
./artisan dusk:install

# or update it:
./artisan dusk:update
```

You need to set the `APP_URL` environment variable in your `.env file`. This value should match the URL you use to access your application in a browser.

## Test Database - Users, Passwords and API Keys

| Username | Privilege | Password | API Key |
|:--|:--|:--|:--|
| `travis` | *SUPERADMIN* | `travisci` | `Syy4R8uXTquJNkSav4mmbk5eZWOgoc6FKUJPqOoGHhBjhsC9` |
| `imcustadmin` | *CUSTADMIN* | `travisci` |  `Syy4R8uXTquJNkSav4mmbk5eZWOgoc6FKUJPqOoGHhBjhsC8` |
| `hecustadmin` | *CUSTADMIN* | `travisci` | |
| `imcustuser` | *CUSTUSER* | `travisci` | `Syy4R8uXTquJNkSav4mmbk5eZWOgoc6FKUJPqOoGHhBjhsC7` |
| `hecustuser` | *CUSTUSER* | `travisci` | |


## Running Unit Tests

In one console session, start the artisan / Laravel web server:

```sh
# move to the root directory of IXP Manager
cd $IXPROOT
php artisan serve
```

If you are running Dusk tests, also start the Chromium driver in another console session. For example:

```sh
./vendor/laravel/dusk/bin/chromedriver-mac-arm --port=9515
```

And then kick off **all the tests** which includes PHPUnit and Laravel Dusk tests, run:

```sh
$ php artisan test

  ...
  ...

  Tests:    316 passed (3206 assertions)
  Duration: 139.11s
```

You can also use PHPUnit directly:

```sh
❯ ./vendor/bin/phpunit
PHPUnit 11.5.33 by Sebastian Bergmann and contributors.

Runtime:       PHP 8.4.11
Configuration: /Users/barryo/dev/ixpm-inex/phpunit.xml

...............................................................  63 / 371 ( 16%)
............................................................... 126 / 371 ( 33%)
............................................................... 189 / 371 ( 50%)
............................................................... 252 / 371 ( 67%)
............................................................... 315 / 371 ( 84%)
........................................................        371 / 371 (100%)

Time: 02:48.456, Memory: 96.50 MB

OK (371 tests, 3071 assertions)
```

If you only want to run Laravel Dusk / browser tests, run the following (shown with sample output):

```sh
$ php artisan dusk

   PASS  Tests\Browser\ApiKeyControllerTest

   PASS  Tests\Browser\CabinetControllerTest
   ✓ cabinet
 
   ...

   PASS  Tests\Browser\VlanControllerTest
   ✓ add

  Tests:    24 passed (2259 assertions)
  Duration: 117.17s
```

If you want to exclude the browser based tests, just exclude that directory as follows:

```sh
$ ./vendor/bin/phpunit --filter '/^((?!Tests\\Browser).)*$/'
PHPUnit 11.5.34 by Sebastian Bergmann and contributors.

Runtime:       PHP 8.4.11
Configuration: /Users/barryo/dev/ixpm-inex/phpunit.xml

...............................................................  63 / 372 ( 16%)
............................................................... 126 / 372 ( 33%)
............................................................... 189 / 372 ( 50%)
............................................................... 252 / 372 ( 67%)
............................................................... 315 / 372 ( 84%)
.........................................................       372 / 372 (100%)

Time: 02:57.036, Memory: 98.50 MB

OK (372 tests, 3081 assertions)
```

You can also limit tests to specific test suites:

```
$ ./vendor/bin/phpunit --testsuite 'Dusk / Browser Test Suite'
$ ./vendor/bin/phpunit --testsuite 'Docstore Test Suite'
$ ./vendor/bin/phpunit --testsuite 'IXP Manager Test Suite'
```

Or specific test directories:

```
$ ./vendor/bin/phpunit tests/API
$ ./vendor/bin/phpunit tests/Utils
```


## Running Psalm Static Code Analysis

This is very easy if you've following the above `composer install --dev` step:

```sh
$ ./vendor/bin/psalm
Target PHP version: 8.4 (inferred from current PHP version).

Scanning files...

Analyzing files...

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  60 / 531 (11%)
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 120 / 531 (22%)
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 180 / 531 (33%)
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 240 / 531 (45%)
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 300 / 531 (56%)
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 360 / 531 (67%)
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 420 / 531 (79%)
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 480 / 531 (90%)
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

------------------------------

       No errors found!

------------------------------
```

