# Console Servers

An IXP would typically have out of band access (for emergencies, firmware upgrades, etc) to critical infrastructure devices by means of a console server.

**IXP Manager** has *Console Servers* and *Console Server Connections* menu options to allow IXP administrators add / edit / delete / list console server devices and, for any such device, record what console server port is connected to what device (as well as connection characteristics such as baud rate).

From **IXP Manager v4.8.0** onwards, each of these pages has a notes field which supports markdown to allow you to include sample connection sessions to devices. This is especially useful for rarely used console connections to awkward devices.

## Improvements from v4.8.0

One of the new features of v4.8.0 is fixing the switch database table which until now could hold switches and console servers. This was awkward in practice and we have split these into distinct database tables and menu options.
