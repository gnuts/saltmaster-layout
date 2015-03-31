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

Add your minion "proxy" to /etc/saltmaster-layout/callminions.conf:

    servers="host.example.ninja:22"

Now you can start callminions in an interactive shell. It supports some keyboard commands that are explained on screen.

Hint: the "connection test" command can be used to accept fingerprints of servers you contact for the first time.
This can be useful, if you have lots of hosts in your "servers" line.


Release Management
==================

The included Makefile is intended for teams working on the same saltmaster installation. It helps to avoid race conditions where
multiple admins change the pillar and want to deploy their changes.

When using the Makefile, the following rules apply:

* /srv/salt/ is read only. You never change anything there. Never.
* Each change implies that you roll a new release.
* The only thing you do in /srv/salt is checking out a release.
* If you need to change the pillar or a local formula, you need to clone the git repository of the salt installation in your own working directory.
* you need to use git-flow. to make a new release, your changes have to be merged to the develop branch.
* never commit anything directly to the master branch.
* when checking in a new release, describe your changes in the tag message.

This sounds like a lot, but it really helps to keep your salt pillar intact and transparent. It may be overkill, if you are the only one that changes the pillar.
But even then it might be worth it if you for example need to roll back fast to a working version.

You can also use this to set up a quality control instance.

The workflow could be:

* There is a development repository and a production repository. The dev repo is a fork of the prod repo.
* An admin changes something in the pillar and pushes his changes to the dev repo.
* He then creates a pull request in the production repository.
* A QA guy takes on the pull request, does whatever is needed to audit the change, and finally accepts or rejects the pull request.
* If the request is accepted, the QA person creates a new release.
* The release is now available on the saltmaster and can be checked out.

The Makefile supports a few commands:

make help
---------

Shows a command summary

make version
------------

Shows the currently checked out version

make list
---------

Lists the last 10 releases

make release
------------

Start a new release. You need to be on the develop branch. Everything must be commited.
There must be no other release branch.

At first this command will update the master and develop branches!

The command will ask you for a version number. It automatically increases the last version by one, but you can change that if you need to.
Then it creates a release branch and immediately pushes it to the repository.
As long as your release is open, noone else can create a release, so make sure to finish your
release in a timely manner.

After the release has been started, do your final changes. Usually, there is nothing to do.
The next thing to do is "make finish". In most cases you actually can create a release by calling

    make release finish


make finish
-----------

This command will merge develop to master, remove the release branch, create a release tag and push everything to the remote.

make update
-----------

updates the master and develop branches


make select
-----------

Fetchs the current repository from remote and shows a list of the latest versions.
It asks you which version shall be checket out. By default, the latest one is selected.
This checks out the release tag - the message about detached head is completely fine.

**You should never change anything in /srv/salt, only check out releases!**

other commands
--------------

make pushall
make prune
make listrc
make lock
make unlock
make rc



