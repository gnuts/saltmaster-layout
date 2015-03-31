Saltmaster-Layout
=================

A Debian package containing a basic salt-master infrastructurei, utilities and many formulas from github.

Features
--------

* callminions utility: a ssh reverse tunnel script to contact minions accross firewalls
* install-minion utility: small wrapper for bootstrap-salt for easy remote minion installation
* bootstraplayout utility: installs a saltmaster layout ready to use.
* Makefile: a makefile that implements release management of a salt-master installation in a git repository

Formulas
--------

To see which formulas are included, have a look at /usr/share/doc/saltmaster-layout/formulas.txt or
https://github.com/gnuts/saltmaster-layout/blob/master/formulas-lib/formulas.conf

Usage
=====

After installing the debian package, you can bootstrap your salt-master directory using::

    salt-bootstraplayout


It will ask some questions about directories and permissions. By default it will setup a directory structure like this::


  ├── Makefile
  ├── formulas
  │   ├── formulamap.sls
  │   └── top.sls
  └── pillar
      ├── auth
      ├── hostmap.sls
      ├── hosts
      └── top.sls
  
