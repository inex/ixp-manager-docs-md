# Release Procedure

## Branch Overview

There are typically three types of branches on [IXP Manager's GitHub repository](https://github.com/inex/IXP-Manager/branches):

1. The `main` branch is where new features, improvements and bug fixes are staged before release. These will not necessary have gone through our formal pre-release testing (unit tests, static code analysis, etc.), and so should not be considered safe for production.
2. The `release-vX` branches are where we stage code for release that is considered safe to `git pull` on an installation of IXP Manager already running at the most recent release. While we would not ordinarily include database migrations in these 'between release' commits, the standard upgrade process should be followed.
3. All other branches are work in progress.


## Release Procedure

1. Update the `.env.example` file with new options and comments.
2. Draft release notes on GitHub.
3. Ensure all third-party libraries and dependencies have been updated. 
   ```sh
   composer update
   ```
4. Ensure all asset libraries have been updated, and assets have been built for production,
   ```sh
   npm update
   npm run prod
   ```
5. Update the IXP Manager automated installation script if necessary.
6. Merge `main` into `release-vX`:
   ```sh
   git checkout release-vX
   git rebase/merge main
   ```
7. Update any necessary documentation on https://docs.ixpmanager.org/. Also update the current and development tags so that the versioned documenation will default to the new release major.minor if necessary.
8. Run the full suite of PHPUnit tests and Pslam static code analysis:
   ```sh
   # in one tab:
   php artisan serve

   # in another:
   ./vendor/laravel/dusk/bin/chromedriver-mac-arm --port=9515

   # and then run the tests:
   cp .env.ci .env
   cat data/ci/ci_test_db.sql | mysql -u root ixp_ci
   ./vendor/bin/phpunit

   # static code analysis:
   ./vendor/bin/psalm --clear-cache
   ./vendor/bin/psalm --use-baseline=psalm-baseline.xml
   ```
   If there are any issues, correct them and rerun. Once they run cleanly, copy the output for the release notes.
9. Push the release-vX branch to GitHub, and check for any remaining issues on Dependabot. If there are issues, address them.
10. Ensure the GitHub Action's runner completes cleanly (GitHub runs of PHPUnit and psalm). If there are issues, address them.
11. Update the version details and tag the GitHub release.
    ```sh
    joe version.php
    git tag vx.y.z
    git commit -am 'Tagging release vx.y.z'
    git push
    git push --tags
    ```
12. Update the draft release notes to reference the tag.
13. Complete internal INEX change management procedures to approve the new release.
14. Publish the new release on GitHub.
15. Create two release announcements, one for the ixpmanager-announce mailing list and one for the discussion list.
