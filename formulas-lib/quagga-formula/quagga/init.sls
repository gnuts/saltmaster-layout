{% from "quagga/map.jinja" import map with context %}                                                                                                           


{% set quagga = pillar.get('quagga', {}) %}
{% set bgpd   = quagga.get('bgpd', False) %}
{% set ripd   = quagga.get('ripd', False) %}
{% set zebra  = quagga.get('zebra', False) %}

quagga_packages:                                                                                                                                                
  pkg.installed:                                                                                                                                                   
    - pkgs:                                                                                                                                                        
      {% for pkg in map.pkgs %}                                                                                                                                    
      - {{ pkg }}                                                                                                                                                  
      {% endfor %}                         

quagga_daemons:
  file.managed:
    - name: {{ map.confdir }}/daemons
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source:   salt://quagga/files/daemons.jinja
    - context:
      bgpd:  {{ bgpd }}
      ripd:  {{ ripd }}

{% if ripd %}
quagga_ripdconf:
  file.managed:
    - name: /etc/quagga/ripd.conf
    - user: quagga
    - group: quaggavty
    - mode: 644
    - template: jinja
    - source:   salt://quagga/files/ripd.conf.jinja
    - context:
      ripd:  {{ ripd }}
      logdir: {{ map.logdir }}
{% endif %}

{% if bgpd %}
quagga_bgpdconf:
  file.managed:
    - name: {{ map.confdir }}/bgpd.conf
    - user: quagga
    - group: quaggavty
    - mode: 644
    - template: jinja
    - source:   salt://quagga/files/bgpd.conf.jinja
    - context:
      bgpd:  {{ bgpd }}
      logdir: {{ map.logdir }}

# this should not be done here.
# maybe introduce a resourceservice pillar that disables
# services that are run als cluster resource...
# quagga_service:
#   service.disabled:
#     - name: quagga

{% endif %}

{% if zebra %}
quagga_zebraconf:
  file.managed:
    - name: {{ map.confdir }}/zebra.conf
    - user: quagga
    - group: quaggavty
    - mode: 644
    - template: jinja
    - source:   salt://quagga/files/zebra.conf.jinja
    - context:
      ripd:  {{ ripd }}
{% endif %}

{% if map.debian  %}
quagga_debianconf:
  file.managed:
    - name: {{map.confdir}}/debian.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source:   salt://quagga/files/debian.conf.jinja
    - context:
{% endif %}

