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

After installing the debian package, you can bootstrap your salt-master directory using:

    salt-bootstraplayout


It will ask some questions about directories and permissions. By default it will setup a directory structure like this:

    /srv/salt
    ├── Makefile
    ├── formulas
    │   ├── formulamap.sls
    │   └── top.sls
    └── pillar
        ├── auth
        ├── hostmap.sls
        ├── hosts
        └── top.sls


By default, everybody in the group "staff" will have write access to the saltmaster pillar.

Next, i recommend you enable revision control in this directory:

    git init

If you want to use the Makefile, you will also need git-flow

    git flow init

Accept all defaults of git-flow.

Some basic constraints:

* **Always work in branch develop! Never change anything in branch master!**
* **Do not work as root** Everybody working with saltmaster-layout should have an user account and be member of group "staff" (or whatever you chose during bootstrap)


How it works
============    
