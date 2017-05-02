# Continuous Integration

IXP Manager grew out of a code base and schema that started in the early '90s. Long before [test driven development](http://phpunit.de/) or [behaviour driven development](http://behat.org/) was fashionable for PHP. However, as IXP Manager is taking over more and more critical configuration tasks, we need to back fill some automated testing with continuous integration.

For this we have chosen [Travis-CI](https://travis-ci.org/inex/IXP-Manager) which provides free cloud based CI linked with GitHub for open source projects. Our current build status is: [![Build Status](https://travis-ci.org/inex/IXP-Manager.png?branch=master)](https://travis-ci.org/inex/IXP-Manager)

We won't be aggressively writing tests for the existing codebase but will add tests as appropriate as we continue development. What follows is some basic instructions on how to set up tests and an overview (or links) to tests we have implemented.

## Setting Up PHPUnit Tests

**DISCLAIMER:** This is not a tutorial on unit testing, phpunit or anything else. If you have no experience with these tools, please read up on them elsewhere first.

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

## Running Tests

In one console session, start the artisan / Laravel web server:

```sh
# move to the root directory of IXP Manager
cd $IXPROOT
php artisan serve
```

And then kick off the tests:

```sh
phpunit
```

Sample output:

```
PHPUnit 6.1.0 by Sebastian Bergmann and contributors.

...............                                                   15 / 15 (100%)

Time: 1.65 seconds, Memory: 32.00MB

OK (15 tests, 67 assertions)
```
