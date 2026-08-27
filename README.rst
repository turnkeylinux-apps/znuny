Znuny - Open Source Service Desk
================================

Znuny_ is an open source ticketing and service-desk system for customer
support, sales, billing, internal IT, and help-desk teams. It continues the
former ``((OTRS)) Community Edition`` code line as an independently maintained
project.

This is a separate TurnKey Znuny appliance. It is not the current commercial
OTRS product and is not endorsed by that vendor. Debian retains historical
OTRS-compatible package and runtime names for Znuny; these compatibility
interfaces do not change the appliance's product identity.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- Znuny configurations:
   
   - Installs the security-supported Znuny 6.5 LTS line from Debian 13
     package management.
   - Includes spell checking.

- SSL support out of the box.
- Includes TurnKey web control panel (convenience).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, MySQL, Postfix and Procmail

Customer registration requires valid networking configuration (email
support).

Check the Debian update channel with ``turnkey-znuny-update --check``. Apply an
available package update with ``turnkey-znuny-update --apply``.

Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MySQL: username **root**
-  Znuny: username **root@localhost**


.. _Znuny: https://www.znuny.org/
.. _TurnKey Core: https://www.turnkeylinux.org/core
