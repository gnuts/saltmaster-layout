==============
network-debian
==============

Formula to install and configure networking under debian.

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``network-debian``
-----------

Installs and configures network.

``network-debian.bridge``
-------------------

Install required packages for ethernet bridging.

``network-debian.vlan``
-------------------

Install required packages for using vlans.

Example
=======

See *network-debian/pillar.example*.

Notes
=====

* This formula does not modify any running network configuration, it just modifies configuration files. To activate any network configuration restart networking or reboot the device.
