# This is the main state file for configuring ssh.

{% from "ssh/map.jinja" import map with context %}

# Install packages
ssh_pkgs:
  pkg.installed:
    - pkgs:
      {% for pkg in map.pkgs %}
      - {{pkg }}
      {% endfor %}

# Ensure ssh service is running and autostart is enabled
ssh_service:
  service.running:
    - name: {{ map.service }}
    - enable: True
    - require:
      - pkg: ssh_pkgs

# Deploy sshd_config
ssh_server_config:
  file.managed:
    - name: {{ map.conf_dir }}/{{ map.conf_file }}
    - source: salt://ssh/files/sshd_config.jinja
    - template: jinja  
    - user: {{ map.user }}
    - group: {{ map.group }}
    - mode: {{ map.mode }}  
    - watch_in:
      - service: ssh_service
