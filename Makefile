#!/usr/bin/make

PNAME    		= saltmaster-layout
PDESC    		= saltmaster-layout - a basic salt master infrastructure and many formulas from github 

REPOSITORY 	= "deb.mawoh.org"
REPODIR 		= "/var/www/reprepro"
DISTNAME    = mawoh

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
	echo "nothing to do"
	#make -f Makefile.sphinx html

update-binversion:
	perl -p -i -e "s/__version__/$(DEBVERSION)/" $(INST_BINDIR)/* 

install: clean update-doc 
	@echo "installing $(PNAME) $(DEBVERSION) build $(BUILD)"
	#
	# create directories
	#
	mkdir -p $(INST_BINDIR)
	mkdir -p $(INST_ETCDIR)
	mkdir -p $(INST_USRSHAREDIR)
	mkdir -p $(INST_USRSHAREDOCDIR)
	mkdir -p $(INST_LIBDIR)
	mkdir -p $(INST_LIBDIR)/formulas
	mkdir -p $(INST_LIBDIR)/extensions

	#
	# binaries
	#
	install -g root -o root -m 755 bin/salt-callminions  $(INST_BINDIR)/
	install -g root -o root -m 755 bin/salt-install-minion $(INST_BINDIR)/
	install -g root -o root -m 755 bin/salt-bootstraplayout $(INST_BINDIR)/
	install -g root -o root -m 755 bin/formula-doc $(INST_BINDIR)/
	
	#
	# install template and extensions
	#
	rsync -r  --exclude '.keep' template $(INST_USRSHAREDIR)/
	rsync -r  --exclude '.keep' extensions  $(INST_LIBDIR)/
	rsync -r  --exclude '.keep' lib/ $(INST_LIBDIR)/
	rsync -r  --exclude '.keep' etc/ $(INST_ETCDIR)/
	chown -R root:root $(INST_USRSHAREDIR) $(INST_LIBDIR)
	chmod -R u=rwX,go=rX $(INST_USRSHAREDIR) $(INST_LIBDIR) $(INST_ETCDIR) 
	cp $(INST_LIBDIR)/Makefile $(INST_USRSHAREDIR)/template/
	# 
	# copy formulas to doc and lib
	# 
	formulas=$$(cut -d" " -f1 formulas-lib/formulas.conf) && \
	for fname in $$formulas; do \
		echo "install formula $$fname" ; \
		rsync -r --exclude '.keep' "formulas-lib/$${fname}-formula/$${fname}" "$(INST_LIBDIR)/formulas/" ; \
		mkdir "$(INST_USRSHAREDOCDIR)/$${fname}" ; \
		rsync -q --exclude '.keep' formulas-lib/$${fname}-formula/* "$(INST_USRSHAREDOCDIR)/$${fname}/" ; \
		rsync -qr --exclude '.keep' "formulas-lib/$${fname}-formula/$${fname}" "$(INST_LIBDIR)/formulas/" ; \
	done

  # copy config files to doc dir too
	cp etc/callminions.conf $(INST_USRSHAREDOCDIR)/callminions.conf.example
	cp etc/salt.conf $(INST_USRSHAREDOCDIR)/salt.conf.example

	# add formulas information to doc dir
	echo "This package contains the following formulas (name, branch and url):" >$(INST_USRSHAREDOCDIR)/formulas.txt
	echo >>$(INST_USRSHAREDOCDIR)/formulas.txt
	sort formulas-lib/formulas.conf >> $(INST_USRSHAREDOCDIR)/formulas.txt
	make update-binversion

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
	dch  --force-distribution -D stable -v "$(NEWVERSION)" "new release"
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
	rsync -vP ../packages/$(PNAME)*deb root@$(REPOSITORY):/tmp/ 
	ssh -l root $(REPOSITORY) 'cd $(REPODIR) && for f in /tmp/*deb; do reprepro includedeb $(DISTNAME) $$f;done'

copydeb:
	rsync -Pva ../packages root@saltmaster:


