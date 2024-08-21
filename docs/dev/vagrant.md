# Vagrant

For development purposes, we have Vagrant build files.

The Vagrant file was updated for IXP Manager v7.

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

1. Install Vagrant (see: https://developer.hashicorp.com/vagrant/install)
2. Install VirtualBox (see: https://www.virtualbox.org/)
3. Install the [Parallels provider](https://github.com/Parallels/vagrant-parallels). E.g., on MacOS when Vagrant is installed via Homebrew:
   ```sh
   brew install hashicorp/tap/hashicorp-vagrant
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

Spinning up Vagrant in the above manner loads a sample database from `ixpmanager/database/schema/vagrant-base.sql`. If you have a preferred development database, place a bzip'd copy of it in the `ixpmanager` directory called `ixpmanager-preferred.sql.bz2` before step 5 above.
