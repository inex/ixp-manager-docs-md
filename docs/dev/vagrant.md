# Vagrant

For development purposes, we have Vagrant build files.

The Vagrant file was updated for IXP Manager v7.

The entire system is built from a fresh Ubuntu 24.04 installation via the `tools/vagrant/bootstrap.sh` script. This also installs a systemd service to run `tools/vagrant/startup.sh` on a reboot to restart the various services.

## Quick Vagrant with VirtualBox

*Note the developers use Parallels (see below) and have not tested on VirtualBox for sometime.*

If you want to get IXP Manager with Vagrant and VirtualBox up and running quickly, follow these steps:

1. Install Vagrant (see: https://developer.hashicorp.com/vagrant/install)
2. Install VirtualBox (see: https://www.virtualbox.org/)
3. Clone IXP Manager to a directory:

    ```sh
    git clone https://github.com/inex/IXP-Manager.git ixpmanager
    cd ixpmanager
    ```

4. Edit the `Vagrantfile` in the root of IXP Manager and delete the `config.vm.provider "parallels" do |prl|` block and uncomment the `config.vm.provider "virtualbox" do |vb|`.

4. Spin up a Vagrant virtual machine:

    ```
    vagrant up
    ```

## Quick Vagrant with Parallels

1. Install Vagrant (see: https://developer.hashicorp.com/vagrant/install). On MacOS:
   ```sh
   brew tap hashicorp/tap
   brew install hashicorp/tap/hashicorp-vagrant
   ```
2. Install Parallels (see: https://www.parallels.com/)
3. Install the [Parallels provider](https://github.com/Parallels/vagrant-parallels). E.g., on MacOS when Vagrant is installed via Homebrew:
   ```sh
   vagrant plugin install vagrant-parallels
   ```
4. Clone IXP Manager to a directory:
    ```sh
    git clone https://github.com/inex/IXP-Manager.git ixpmanager
    cd ixpmanager
    ```
5. Spin up a Vagrant virtual machine:
    ```
    vagrant up
    ```


## Next Steps - Access IXP Manager

1. Access IXP Manager on: http://localhost:8088/

2. Log in with one of the following username / passwords:

   - Admin user: `vagrant / Vagrant1` (api key: `r8sFfkGamCjrbbLC12yIoCJooIRXzY9CYPaLVz92GFQyGqLq`)
   - Customer Admin: `as112 / AS112as112`
   - Customer User: `as112user / AS112as112`


## Vagrant Notes

Please see Vagrant's own documentation for a full description of how to use it fully. 

* To access the virtual machine that the above has spun up, just run the following from the `ixpmanager` directory:

    ```
    vagrant ssh
    ```

* Once logged into the Linux machine, you'll find the `ixpmanager` directory mounted under `/vagrant`. 
* You can `sudo su -` 
* You can access MySQL using `root/password` via:
    * Locally: `mysql -u root -ppassword ixp`
    * From the machine running Vagrant: `mysql -u root -ppassword -h 127.0.0.1 -P 33061`
    * Via phpMyAdmin on http://127.0.0.1:8088/phpmyadmin
* As mentioned above, the IXP Manager application is mounted under `/vagrant` in the Vagrant virtual machine. This is mounted as the `vagrant` user. Any changes made on your own machine are immediately reflected on the virtual machine and vice-versa.
* Apache runs as `vagrant` to avoid all file system permission issues.


## Database Details

Spinning up Vagrant in the above manner loads a sample database from `tools/vagrant/vagrant-base.sql`. If you have a preferred development database, place a bzip'd copy of it in the `ixpmanager` directory called `ixpmanager-preferred.sql.bz2` before step 5 above.


## SNMP Simulator and MRTG

The Vagrant bootstrapping includes installing [snmpsim](https://github.com/etingof/snmpsim) making three *"switches"* matching those in the supplied database available for polling. The source snmpwalks for these are copied from `tools/vagrant/snmpwalks` to `/srv/snmpclients` and values can be freely edited there.

Example of polling when ssh'd into vagrant:

```
snmpwalk -c swi1-fac1-1 -v 2c swi1-fac1-1
snmpwalk -c swi1-fac2-1 -v 2c swi1-fac1-1
snmpwalk -c swi2-fac1-1 -v 2c swi2-fac1-1
```

As you can see, the community selects the source file - i.e., `-c swi1-fac1-1` for `/srv/snmpclients/swi1-fac1-1.snmprec`. The Vagrant bootstrap file adds these switch names to `/etc/hosts` also.

The bootstrapping also configures mrtg to run and includes this in the crontab rather than using dummy graphs. The snmp simulator has some randomised elements for some of the interface counters.

## Route Server / Collector and Looking Glass

When running `vagrant up` for the first time, it will create a full route server / collector /as112 testbed complete with clients:

* Route servers, collectors and AS112 BIRD daemons are started from hardcoded handles based on the Vagrant test database.
* Client router BIRD instances (dual-stack v4/v6) are generated and started based on their vlan interfaces as at the time the scripts are run.

All BIRD instance sockets are located in `/var/run/bird/` allowing you to connect to them using `birdc -s /var/run/bird/xxx.ctl`.

In additional to this, a second Apache virtual host is set up listening on port 81 locally providing access to Birdseye installed in `/srv/birdseye`. The bundled Vagrant database is already configured for this and should work out of the box. All of Birdseye's env files are generated via: 

    php /vagrant/artisan vagrant:generate-birdseye-configurations

Various additional scripts support all of this:

1. The `tools/vagrant/bootstrap.sh` file which sets everything up.
2. `tools/vagrant/scripts/refresh-router-testbed.sh` will reconfigure all routers.
3. `tools/vagrant/scripts/as112-reconfigure-bird2.sh` will (re)configure and start, if necessary, the AS112 BIRD instances.
4. `tools/vagrant/scripts/rs-api-reconfigure-all.sh` will (re)configure and start, if necessary, the route server BIRD instances.
5. `tools/vagrant/scripts/rc-reconfigure.sh` will (re)configure and start, if necessary, the route collector BIRD instances.

For the clients, we run the following:

```sh
mkdir -p /srv/clients
chown -R vagrant: /srv/clients
php /vagrant/artisan vagrant:generate-client-router-configurations
chmod a+x /srv/clients/start-reload-clients.sh
/srv/clients/start-reload-clients.sh
```


All router IPs are added to the loopback interface as part of the `tools/vagrant/bootstrap.sh` (or the `startup.sh` script on a reboot). There are also necessary entries in `/etc/hosts` to map router handles to IP addresses. There are two critical BIRD BGP configuration options to allow multiple instances to run on the same server and speak with each other:

```
strict bind yes;
multihop;
```


# AS112 Testbed

In addition to the AS112 BIRD service above, we also build a fully working AS112 service using PowerDNS, with the AS112 IP addresses assign to the loopback interface.

We include a PHP test script for testing this also:

```
# cd /vagrant/tools/runtime/as112/

# php as112-test.php
  ___   _____ __   __   _____   _____         _
 / _ \ /  ___/  | /  | / __  \ |_   _|       | |
/ /_\ \ `--.`| | `| | `' / /'   | | ___  ___| |_ ___ _ __
|  _  | `--. \| |  | |   / /     | |/ _ \/ __| __/ _ \ '__|
| | | |/\__/ /| |__| |_./ /___   | |  __/\__ \ ||  __/ |
\_| |_/\____/\___/\___/\_____/   \_/\___||___/\__\___|_|

(c) 2009 - 2025 Internet Neutral Exchange Association Company Limited By Guarantee.

Part of the IXP Manager project - see https://github.com/inex/IXP-Manager

This script tests AS112 servers as follows:

- hostname.as112.net TXT records
- hostname.as112.arpa TXT records

And 10 random PTR queries for each of the following:

- 10.in-addr.arpa PTR records
- 168.192.in-addr.arpa PTR records
- 172.in-addr.arpa PTR records
- 254.169.in-addr.arpa PTR records

Starting...

Testing 192.175.48.1:       ....................................................................................
Testing 192.175.48.6:       ....................................................................................
Testing 192.175.48.42:      ....................................................................................
Testing 192.31.196.1:       ....................................................................................
Testing 2620:4f:8000::1:    ....................................................................................
Testing 2620:4f:8000::6:    ....................................................................................
Testing 2620:4f:8000::42:   ....................................................................................
Testing 2001:4:112::1:      ....................................................................................


Done in 0.08 seconds (672 queries in 0.060029983520508 secs).
```

