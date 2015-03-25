
{% from "heartbeat/map.jinja" import map with context %}

heartbeat_packages:
  pkg.installed:
    - pkgs:
      {% for pkg in map.pkgs %}
      - {{pkg }}
      {% endfor %}

# configure heartbeat
#
heartbeat_haresources:
  file.managed:
    - name: {{map.confdir}}/haresources
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source:   salt://heartbeat/files/haresources.jinja
    - context:
      nodes:  {{ pillar.heartbeat.nodes }}

heartbeat_hacf:
  file.managed:
    - name: {{map.confdir}}/ha.cf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source:   salt://heartbeat/files/ha.cf.jinja
    - context:
      nodes:  {{ pillar.heartbeat.nodes }}

heartbeat_authkeys:
  file.managed:
    - name: {{map.confdir}}/authkeys
    - user: root
    - group: root
    - mode: 600
    - template: jinja
    - source:   salt://heartbeat/files/authkeys.jinja
    - context:
      defaultkey: {{ pillar.heartbeat.auth.defaultkey }}
      authkeys:   {{ pillar.heartbeat.auth.authkeys }}


# reload heartbeat, if:
# - any of the files changed
# TODO: user service state to reload, not cmd
#
reload_heartbeat:
  cmd.wait:
    - name: /etc/init.d/{{map.servicename}} reload
    - watch:
      - file: /etc/heartbeat/ha.cf
      - file: /etc/heartbeat/haresources
      - file: /etc/heartbeat/authkeys




