# Continuous Integration

IXP Manager grew out of a code base and schema that started in the early '90s. Long before [test driven development](http://phpunit.de/) or [behaviour driven development](http://behat.org/) was fashionable for PHP. However, as IXP Manager is taking over more and more critical configuration tasks, we continue to back fill some automated testing with continuous integration for critical elements.

We use [Travis-CI](https://travis-ci.org/inex/IXP-Manager) for continuous integration (CI) who provide free cloud based CI linked to GitHub for open source projects.

Our current build status is: [![Build Status](https://travis-ci.org/inex/IXP-Manager.png?branch=master)](https://travis-ci.org/inex/IXP-Manager)

The CI system runs the full suite of tests every time a commit is pushed to GitHub. As such, any *build failing* states are usually transitory. **Official IXP Manager releases are only made when all tests pass.**

We use two types of unit tests:

1. [PHP Unit](http://phpunit.de/) for standard unit tests;
2. [Laravel Dusk](https://laravel.com/docs/5.6/dusk) for browser based tests.

We won't be aggressively writing tests for the existing codebase but will add tests as appropriate as we continue development. What follows is some basic instructions on how to set up tests and an overview (or links) to some of the tests we have implemented.

**DISCLAIMER:** This is not a tutorial on unit testing, phpunit, Laravel Dusk or anything else. If you have no experience with these tools, please read up on them elsewhere first.


## Setting Up PHPUnit Tests

Documentation by real example can be found via the [.travis.yml](https://github.com/inex/IXP-Manager/blob/master/.travis.yml) file and [the Travis data directory](https://github.com/inex/IXP-Manager/tree/master/data/travis-ci) which contains scripts, database dumps and configurations.

Testing assumes *a known good sample database* which contains a small mix of customers with different configuration options. The files generated from this database are tested against [known good](https://github.com/inex/IXP-Manager/tree/master/data/travis-ci/known-good) configuration files. You first need to create a database, add a database user, import this testing database and then configure a `.env` section for testing.

In MySQL:

```mysql
CREATE DATABASE ixp_ci CHARACTER SET = 'utf8mb4' COLLATE = 'utf8mb4_unicode_ci';
GRANT ALL ON `ixp_ci`.* TO `ixp_ci`@`localhost` IDENTIFIED BY 'somepassword';
FLUSH PRIVILEGES;
```

Then import the sample database:

```sh
bzcat data/travis-ci/travis_ci_test_db.sql.bz2  | mysql -h localhost -u ixp_ci -psomepassword ixp_ci
```

Now, create your `.env` for testing, such as:

```ini
DB_HOST=localhost
DB_DATABASE=ixp_ci
DB_USERNAME=ixp_ci
DB_PASSWORD=somepassword
```

Note that the [`phpunit.xml`](https://github.com/inex/IXP-Manager/blob/master/phpunit.xml) file in the root directory has some default settings matching the test database. You should not need to edit these.

The `.env` file used by Travis CI can be [seen here](https://github.com/inex/IXP-Manager/blob/master/.env.travisci) and - as it's used by Travis CI to run the tests - it should be a complete example of what is required.

## Setting Up Laravel Dusk

Please review the [official documentation here](https://laravel.com/docs/5.6/dusk).

You need to ensure the development packages for IXP Manager are installed via:

```sh
# move to the root directory of IXP Manager
cd $IXPROOT
composer install --dev
```

You need to set the `APP_URL` environment variable in your `.env file`. This value should match the URL you use to access your application in a browser.

## Test Database Notes

1. The *SUPERADMIN* username / password is one-way hashed using bcrypt. If you want to log into the frontend of the test database, these details are: `travis` / `travisci`.
2. There are two test *CUSTADMIN* accounts which can be accessed using username / password: `hecustadmin` / `travisci` and `imcustadmin` / `travisci`.
3. There are two test *CUSTUSER* accounts which can be accessed using username / password: `hecustuser` / `travisci` and `imcustuser` / `travisci`.

## Running Tests

In one console session, start the artisan / Laravel web server:

```sh
# move to the root directory of IXP Manager
cd $IXPROOT
php artisan serve
```

And then kick off **all the tests** which includes PHPUnit and Laravel Dusk tests, run:

```sh
phpunit
```

Sample output:

```
PHPUnit 7.2.2 by Sebastian Bergmann and contributors.

...............................................................  63 / 144 ( 43%)
............................................................... 126 / 144 ( 87%)
..................                                              144 / 144 (100%)

Time: 1.86 minutes, Memory: 103.73MB
```

If you only want to run Laravel Dusk / browser tests, run the following (shown with sample output):

```sh
$ php artisan dusk
PHPUnit 6.5.8 by Sebastian Bergmann and contributors.

..                                                                  2 / 2 (100%)

Time: 12.73 seconds, Memory: 24.00MB
```

If you want to exclude the browser based tests, just exclude that directory as follows:

```sh
$ phpunit --filter '/^((?!Tests\\Browser).)*$/'
PHPUnit 7.2.2 by Sebastian Bergmann and contributors.

...............................................................  63 / 142 ( 44%)
............................................................... 126 / 142 ( 88%)
................                                                142 / 142 (100%)

Time: 1.59 minutes, Memory: 106.41MB
```
