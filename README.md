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

Installation
============

Note: for details on how salt itself works, please refer to the excellent saltstack documentation:

http://docs.saltstack.com/en/latest/

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

* **Always work in branch develop! Never change anything in branch master!** The master branch is reserved for releases.
* **Do not work as root!** Everybody working with saltmaster-layout should have an user account and be member of group "staff" (or whatever you chose during bootstrap)


Adding a host
=============

Install a minion using the salt-install-minion utility:

    salt-install-minion myminion.example.ninja saltmaster.example.ninja

you can also specify a webproxy+port if you need to:

    salt-install-minion myminion.example.ninja saltmaster.example.ninja proxy.example.ninja 8080

This uses the salt-bootstrap script from saltstack: https://github.com/saltstack/salt-bootstrap

Add your minion's key:

    salt-key -a myminion.example.ninja


Now add a pillar for this host. For this, create a SLS file in /srv/salt/hosts.
The file name must be the hosts FQDN of the host (as reported by salt-key) with all dots (.) replaced with dashes (-):

example: /srv/salt/hosts/myminion-example-ninja.sls:


    # very simple, senseless pillar for demonstration!
    #
    # include these formulas:
    formulas:
        users

    users:
      leo:
      mike:
      raph:
      don:

Using callminions
=================

Salt-callminion can be used to make a saltmaster temporarily availabe to minions that would otherwise not be able to access the saltmaster.
For example if your minions are in the DMZ and the saltmaster is in an intranet zone.
Callminions uses ssh to start reverse tunnels on a selected machine in your DMZ. The minions can then be configured, to use this machine as
saltmaster.

This tool is ment to be used in an interactive session, e.g. in a screen session to make the minions available for a short period of time.
Start the session, deliver highstates, shut down the session. This is not a replacement for a VPN connection or firewall settings! If
you need permanent availability of the minions to the saltmaster, callminions is not the solution!

Also note that you have to enable Gatewayports in your sshd config on the minion-proxy. This may be a security concern to you, as it allows ssh
tunnels to listen on the master socket.

**Make sure to know what you are doing.**

Add this line to sshd config at the minion-proxy:

    GatewayPorts clientspecified



