#
# Regular cron jobs for the saltmaster-layout package
#
0 4	* * *	root	[ -x /usr/bin/saltmaster-layout_maintenance ] && /usr/bin/saltmaster-layout_maintenance
