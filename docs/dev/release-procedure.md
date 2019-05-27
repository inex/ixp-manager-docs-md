# Release Procedure

**DRAFT:** in advance of the v4.8.0 release, I am gathering some notes here towards writing for formal release procedure for new minor versions of IXP Manager.


1. Create a release branch - e.g. `release-v5`.
1. Ensure third party libraries have been updated.
1. Ensure the `.env.example` has been updated with new options and comments.
1. Ensure completed release notes on GitHub.
1. Update the IXP Manager installation script(s) to reference the new **branch** of IXP Manager.
1. Update the Docker files to install the new version of IXP Manager.
1. Update any necessary documentation on https://docs.ixpmanager.org/
1. Tag the GitHub release.
1. Ensure proxies match entities.
1. Ensure production yarn run.
1. Release announcement.
