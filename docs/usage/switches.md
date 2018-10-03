# Switches

Switch functionality is currently being migrated in development from Zend Framework to Laravel. Once that is complete, this documentation will be updated.

In the meantime see: https://github.com/inex/IXP-Manager/wiki/Switch-and-Switch-Port-Management


## Port Audit

A new feature (adding in v4.9.0) allows **IXP Manager** administrators to audit port speeds as configured in [physical interfaces](interfaces.md#physical-interface-settings) against what has been discovered in the last SNMP run.

You can run it from Artisan such as the following example:

```
./artisan audit:port-speeds

Audit of Configured Physical Interface Port Speeds Against SNMP Discovered Speeds

+------------------------------+----------+----------------+-----------------------+----------+------------+
| Customer                     | PI DB ID | Switch         | Switchport            | PI Speed | SNMP Speed |
+------------------------------+----------+----------------+-----------------------+----------+------------+
| INEX Route Servers [AS43760] | 14       | swi2-tcy1-2    | GigabitEthernet27     | 0        | 1000       |
| INEX [AS2128]                | 15       | swi1-ix1-2     | X460-48t Port 47      | 0        | 1000       |
| INEX [AS2128]                | 16       | swi2-ix1-1     | GigabitEthernet25     | 0        | 1000       |
| AS112 Reverse DNS [AS112]    | 21       | swi2-nwb1-1    | X670G2-48x-4q Port 15 | 0        | 1000       |
| INEX [AS2128]                | 357      | swic-cix-2     | GigabitEthernet27     | 100      | 1000       |
| AS112 Reverse DNS [AS112]    | 590      | swt-cwt1-edge1 | swp3                  | 10000    | 1000       |
+------------------------------+----------+----------------+-----------------------+----------+------------+
```

The above examples are edge cases as they are not physically connected devices but rather virtual machines. This audit can be added to cron such that it will only make noise if an issue is found with something like:

```
13 9 * * *   www-data     /srv/ixpmanager/artisan audit:port-speeds \
                            --cron --ignore-pids 14,15,16,21,357,590
```
