# hostmap.sls
#
include:
  - hosts.{{ grains.id|replace(".", "-") }}

