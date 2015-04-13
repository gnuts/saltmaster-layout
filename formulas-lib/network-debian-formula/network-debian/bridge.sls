# network states
# setup bridge environment
#

{%- from 'network-debian/map.jinja' import map with context %}

include:
  - network-debian

network_debian_bridge_pkgs:
  pkg.installed:
    - pkgs:
      {%- for pkg in map.pkgs_bridge %}
      - {{ pkg }}
      {%- endfor %}
