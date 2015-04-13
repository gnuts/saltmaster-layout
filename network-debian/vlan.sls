# network states
# setup vlan environment
#

{%- from 'network-debian/map.jinja' import map with context %}

include:
  - network-debian

network_debian_vlan_pkgs:
  pkg.installed:
    - pkgs:
      {%- for pkg in map.pkgs_vlan %}
      - {{ pkg }}
      {%- endfor %}
