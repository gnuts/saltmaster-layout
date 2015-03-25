#!/usr/bin/make

PNAME		 = saltmaster
BUILD    = $(shell git log --pretty=format:'' | wc -l)
VERSION  = $(shell cat VERSION)
SHELL    = /bin/bash

LOCKFILE = ./LOCK

help: version
	@echo
	@echo "Usage"
	@echo "====="
	@echo "make <command>"
	@echo
	@echo "Commands are:"
	@echo
	@echo "General"
	@echo "======="
	@echo
	@echo "version    show current version of $(PNAME)"
	@echo "list       show availe releases"
	@echo "listrc     show availe releases candidates"
	@echo 
	@echo "For development"
	@echo "==============="
	@echo
	@echo "release    start a new $(PNAME) release"
	@echo "finish     finish new $(PNAME) release)"
	@echo "pushall    run git push --all and git push --tags"
	@echo "prune      remove all locally deleted branches from origin"
	@echo "update     update master and develop branches"
	@echo
	@echo "For production"
	@echo "=============="
	@echo
	@echo "select     select and checkout a release version"
	@echo "lock       lock repository for exclusive use by your userid"
	@echo "unlock     unlock repository. you can only unlock your own lock"
	@echo "rc         checkout a release candidate and lock repository."
	@echo "            you have to tidy up manually when you are done!"


clean:
	echo "not implemented"

test:
	@echo "no tests available"

updateall: 
	@git remote update

lock: checklock
	@id -un >$(LOCKFILE)
	@echo "You now have exclusive access to make targets in this repository"

unlock: checklock
	@rm -f $(LOCKFILE)
	@echo "Lock removed. Access to make targets no longer is exclusive"

checklock:
	@if [ -e "$(LOCKFILE)" ]; then \
		luser=$$(cat $(LOCKFILE)); \
		curr=$$(id -un); \
		if [ "$$luser" != "$$curr" ]; then \
			echo "this repository is locked by user $$luser."; \
			exit 1; \
		fi; \
		echo "repository is locked by you ($$curr)."; \
	fi

checkexclusiverelease:
	@haverelease=$$(git branch -a |grep release/|tail -n1); \
		if [ -n "$$haverelease" ]; then \
			echo "there already is an open release branch:"; \
			echo "$$haverelease"; \
			echo;echo "please finish this release first."; \
			exit 1; \
		fi

checkcommitted:
	@if [ -n "$$(git status -s|grep -vE '^\?')" ]; then \
		echo "there a uncommitted changes:"; \
		git status -s; \
		echo;echo "aborting."; \
		exit 1; \
	fi

checkdevelop:
	@if ! git branch --no-color |grep -q '\* develop$$'; then \
		echo "not in branch develop. merge your changes to develop and try again. e.g. use git flow feature finish"; \
		exit 1; \
	fi

release: checklock checkdevelop checkcommitted updateall checkexclusiverelease update set-debian-release
set-debian-release:
	@if [ -n "$$(git status -s)" ]; then git status -s;echo;echo "there are new files. press CTRL-c to abort or ENTER to continue"; read; fi
	@echo -n "current " && cat VERSION
	@nv=$$(cat VERSION | perl -ne '/^(.*)\.(\d+)/ or die; $$b=$$2+1; print "$$1.$$b"') && \
		echo "enter new version number or press CTRL-c to abort" && \
		echo -n "new version [$$nv]: " && \
		read -ei "$$nv" v && \
		[ -n "$$v" ] || v="$$nv" && \
		echo "ok, new version will be $$v" && \
		NEWVERSION="$$v" make bump && \
		git push -u origin "release/$$v"
	@echo
	@echo
	@echo "when you are done, type \"make finish\""
	@echo
	@echo

bump: checklock
	@if [ -z "$(NEWVERSION)" ]; then echo "need NEWVERSION env var";exit 1;fi
	@echo "starting release $(NEWVERSION)"
	@git flow release start "$(NEWVERSION)"
	@echo "$$NEWVERSION" > VERSION
	@echo "$(BUILD)" > BUILD
	@git commit VERSION BUILD -m "bump version"

pushall: checklock
	@git push -u
	@git push --tags


finish: checklock
	@echo "this will commit all changes, finish the release and push all changes"
	@echo "press ENTER to continue or C-c to abort"
	@read
	@git commit -av || true
	@git flow release finish $(VERSION)
	@make pushall
	# now test and remove release branch locally and remote
	@git branch -D "release/$(VERSION)" || true
	@git push --delete origin "release/$(VERSION)" || true
	@echo
	@echo "done, release $(VERSION) is now available"

version: status
status:
	@echo
	@echo "this is $(PNAME) $(VERSION) commit $(BUILD)"


list: updateall version
	@echo
	@echo "latest releases"
	@echo "---------------"
	@git tag | sort -V | tail -n 10

listrc: updateall
	@echo "latest releases candidates"
	@echo "--------------------------"
	@git branch -a| grep release/


select: checklock list
	@latest=$$(git tag | sort -V | tail -n1) && \
		echo && read -ei "$$latest" -p "select release to check out: " v && \
		echo "---------" && git show --oneline "$$v" && \
		echo && echo "really checkout this version?" && \
		echo "press ENTER to continue or C-C to abort" && read && \
		echo && echo "checking out release $$v" && \
		git checkout "$$v"

rc: checklock listrc
	@latest=$$(git branch -a| grep release/ | sort -V | tail -n1) && \
		echo && read -ei "$$latest" -p "select release candidate to check out: " v && \
		echo "---------" && git show --oneline "$$v" && \
		echo && echo "really checkout this RC version?" && \
		echo "press ENTER to continue or C-C to abort" && read && \
		echo && echo "checking out release candidate  $$v" && \
		git checkout "$$v"

prune: checklock checkcommitted updateall
	@echo "pruning old branches. this will remove the following branches:"
	@read -p "press ENTER to continue or CTRL-c to abort."
	@git push --prune --dry-run

update: checklock checkcommitted updateall
	@branch=$$(git branch --no-color|grep \*|grep -v 'no branch'|rev|cut -d' ' -f1|rev) && \
	if [ -z "$$branch" ]; then \
		echo "not on a branch. cannot update."; \
		exit 1; \
	fi && \
	echo "going to update master and develop repositories, then switching back to current branch ($$branch)"; \
	read -p "press ENTER to continue or CTRL-c to abort"; \
	git checkout master && \
	git pull --all && \
	git checkout develop && \
	git pull --all && \
	git checkout "$$branch"
