# Vagrant

To aid development (as well as allowing easier evaluation), we use [Vagrant](https://www.vagrantup.com/) from v4 onwards.


## Quick Vagrant

> **Temporary issue:** Ubuntu Xenial has a known issue and a couple extra steps are required right now (in the `nf-graphs-decix` branch): https://github.com/inex/IXP-Manager/commit/dd8d256712ec2564eee29aab7cc2eabdf33466d6

If you want to get IXP Manager with Vagrant up and running quickly, follow these steps:

1. Install Vagrant (see: http://docs.vagrantup.com/v2/installation/index.html)
2. Install VirtualBox (see: https://www.virtualbox.org/)
3. Clone IXP Manager to a directory:

    ```sh
    git clone https://github.com/inex/IXP-Manager.git ixpmanager
    cd ixpmanager
    ```

4. Spin up a Vagrant virtual machine:

    ```
    vagrant up
    ```

5. Access IXP Manager on: http://localhost:8088/

6. Log in with one of the following username / passwords:

   - Admin user: `vagrant / vagrant1`
   - Customer Admin: `as112 / as112as112`
   - Customer User: `asii2user / as112as112`

Please see Vagrant's own documentation for a full description of how to use it fully. To access the virtual machine that the above has spun up, just run the following from the `ixpmanager` directory:

```
vagrant ssh
```

You'll find the `ixpmanager` directory mounted under `/vagrant`, you can `sudo su -` and you can access MySQL via:

```
mysql -u root -ppassword ixp
```

If you prefer to use phpMyAdmin, you'll find it at http://localhost:8088/phpmyadmin and you can log in with `root / password`.


## Database Details

Spinning up Vagrant in the above manner loads a sample database from `ixpmanager/database/vagrant-base.sql`. If you have a preferred development database, place a bzip'd copy of it at `ixpmanager/ixpmanager-preferred.sql.bz2` before step 5 above.
