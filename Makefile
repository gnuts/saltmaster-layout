#!/usr/bin/make

PNAME    		= saltmaster-layout
PDESC    		= saltmaster-layout - a basic salt master infrastructure and many formulas from github 

REPOSITORY 		= ""
REPODIR 		= ""

DESTDIR 		?= /
USRPREFIX  		?= /usr
BUILD    		= $(shell git log --pretty=format:'' | wc -l)
DEBVERSION 	= $(shell dpkg-parsechangelog|grep Version:|cut -d" " -f2-)
DEVVERSION  = $(DEBVERSION)-$(BUILD)  

BINDIR  		= $(USRPREFIX)/bin
SBINDIR 		= $(USRPREFIX)/sbin
LIBDIR  		= $(USRPREFIX)/lib/$(PNAME)
VARLIBDIR  		= /var/lib/$(PNAME)
USRSHAREDIR 	= /usr/share/$(PNAME)
USRSHAREDOCDIR 	= /usr/share/doc/$(PNAME)
ETCDIR			= /etc/$(PNAME)
RULESDIR		= /lib/udev/rules.d
SITEDIR			= /srv/saltsite

INST_BINDIR		= $(DESTDIR)/$(BINDIR)
INST_SBINDIR  	= $(DESTDIR)/$(SBINDIR)
INST_LIBDIR   	= $(DESTDIR)/$(LIBDIR)
INST_VARLIBDIR	= $(DESTDIR)/$(VARLIBDIR)
INST_USRSHAREDIR= $(DESTDIR)/$(USRSHAREDIR)
INST_USRSHAREDOCDIR= $(DESTDIR)/$(USRSHAREDOCDIR)
INST_ETCDIR   	= $(DESTDIR)/$(ETCDIR)
INST_RULESDIR 	= $(DESTDIR)/$(RULESDIR)
INST_SITEDIR	= $(DESTDIR)/$(SITEDIR)


SHELL	 		= /bin/bash


BINFILES = salt-callminions salt-install-minion
FORMULAS = conntrack heartbeat network-debian quagga users


.PHONY: help build clean test doc docs update-doc install version release clean upload package

help:
	@echo ""
	@echo "This is the Makefile for $(PNAME) $(DEBVERSION)"
	@echo ""
	@echo "help     this help"
	@echo "version  shows version of $(PNAME) taken from debian/changelog"
	@echo "release  starts workflow to increase version number, create a debian package, and create a git release"
	@echo ""
	@echo "clean    removes tmp/cache files"
	@echo "upload   upload .deb packages to remote debian repo and update reprepo"
	@echo "package  create debian package"
	@echo ""


build: update-version

clean:
	rm -f *~
	rm -f *.8
	rm -f *.1
	rm -f debian/cron.d
	rm -rf itmp
	rm -rf mtmp
	rm -rf debian/$(PNAME)


test:
	@echo "no tests available"


doc docs update-doc:
	#perl -p -i -e "s/___version___/$(DEBVERSION)/" conf.py index.rst
	#make -f Makefile.sphinx html

install: clean update-doc 
	@echo "installing $(PNAME) $(DEBVERSION) build $(BUILD)"
	#
	# create directories
	#
	mkdir -p $(INST_BINDIR)
	#mkdir -p $(INST_SBINDIR)
	mkdir -p $(INST_USRSHAREDIR)
	mkdir -p $(INST_USRSHAREDOCDIR)
	mkdir -p $(INST_LIBDIR)
	mkdir -p $(INST_LIBDIR)/formulas
	mkdir -p $(INST_LIBDIR)/extensions
	#mkdir -p $(INST_SITEDIR)
	#mkdir -p $(INST_SITEDIR)/hosts
	#mkdir -p $(INST_SITEDIR)/groups
	#mkdir -p $(INST_SITEDIR)/files
	#mkdir -p $(INST_SITEDIR)/clusters
	#mkdir -p $(INST_SITEDIR)/states
	#mkdir -p $(INST_SITEDIR)/config
	
	# install template and extensions
	rsync -rv  template $(INST_USRSHAREDIR)/
	rsync -rv  extensions  $(INST_LIBDIR)/
	rsync -rv  lib $(INST_LIBDIR)/
	chown -R root:root $(INST_USRSHAREDIR) $(INST_LIBDIR)
	chmod -R u=rwX,go=rX $(INST_USRSHAREDIR) $(INST_LIBDIR) 

	# now for each formula:
	# copy files from $(formulaname)-formula to $(doc)/formulas/$(formulaname)
	# copy $(formulaname-formula/$(formulaname) to libdir
	
	for fname in $(FORMULAS); do \
		echo "install formula $$fname"; \
		rsync -r "formulas-lib/$${fname}-formula/$${fname}" $(INST_LIBDIR)/formulas/ ; \
		mkdir "$(INST_USRSHAREDOCDIR)/$${fname}" ; \
		( cd "formulas-lib/$${fname}-formula/" && rsync *.rst *.md *.example $(INST_USRSHAREDOCDIR)/$${fname}/ ) ; \
		rsync -r "formulas-lib/$${fname}-formula/$${fname}" $(INST_LIBDIR)/formulas/ ; \
	done

	# install configs
	#mkdir -p $(INST_ETCDIR)

	#
	# binaries
	#
	install -g root -o root -m 755 bin/salt-callminions  $(INST_BINDIR)/
	install -g root -o root -m 755 bin/salt-install-minion $(INST_BINDIR)/
	#cp Makefile.saltsite $(INST_USRSHAREDIR)/saltsite-templates
	
	
	# configuration
	#
	
	# support files
	#
	#install -o root -g root -m 644 share/default.template    $(INST_USRSHAREDIR)


package: docs debian-package move-packages
debian-package:
	debuild --no-tgz-check -uc -us

move-packages:
	@mkdir -p ../packages
	@mv -v ../$(PNAME)_* ../packages | true
	@mv -v ../$(PNAME)-doc_* ../packages | true
	@echo ""
	@echo ""
	@echo "latest package:"
	@ls -lrt ../packages/*.deb|tail -n2

release: set-debian-release
set-debian-release:
	@if ! git branch --no-color |grep -q '\* develop$$'; then echo "not in branch develop. merge your changes to develop and try again."; exit 1; fi
	@if [ -n "$$(git status -s|grep -vE '^\?')" ]; then echo "there a uncommitted changes. aborting"; exit 1; fi
	@if [ -n "$$(git status -s)" ]; then git status -s;echo;echo "there are new files. press CTRL-c to abort or ENTER to continue"; read; fi
	@echo -n "current " && dpkg-parsechangelog|grep Version:
	@nv=$$(echo "$(DEBVERSION)" | perl -ne '/^(.*)\.(\d+)/ or die; $$b=$$2+1; print "$$1.$$b"') && \
		echo "enter new version number or press CTRL-c to abort" && \
		echo -n "new version [$$nv]: " && \
		read -ei "$$nv" v && \
		[ -n "$$v" ] || v="$$nv" && \
		echo "ok, new version will be $$v" && \
		NEWVERSION="$$v" make bump

bump:
	@if [ -z "$(NEWVERSION)" ]; then echo "need NEWVERSION env var";exit 1;fi
	@echo "starting release $(NEWVERSION)"
	git flow release start "$(NEWVERSION)"
	dch  --force-distribution -D stable -v "$(NEWVERSION)" "new release" 2>/dev/null
	@echo -n "Debian new ";dpkg-parsechangelog|grep Version:
	@echo "now run at least the following commands:"
	@echo "# make package"
	@echo "# git commit -av"
	@echo "# git flow release finish $(NEWVERSION)"
	@echo "# git push"
	@echo "# git push --tags"

pushall:
	git push --all
	git push --tags

version: status
status:
	@echo "this is $(PNAME) $(DEBVERSION) commit $(BUILD)"

upload: move-packages
	rsync -vP ../stable/*deb root@$(REPOSITORY):/tmp/ 
	ssh -l root $(REPOSITORY) 'cd $(REPODIR) && for f in /tmp/*deb; do reprepro includedeb squeeze $$f;done'


