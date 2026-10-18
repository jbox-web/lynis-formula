# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- from tplroot ~ "/map.jinja" import lynis with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

{%- if lynis.audit.enabled %}

{%- for unit in ['service', 'timer'] %}
lynis/service/unit/{{ unit }}:
  file.managed:
    - name: /etc/systemd/system/lynis.{{ unit }}
    - source: {{ files_switch(['lynis.' ~ unit ~ '.jinja'],
                              lookup='lynis/service/unit/' ~ unit
                 )
              }}
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - sls: {{ sls_package_install }}
    - context:
        audit: {{ lynis.audit | json }}
        bin: {{ lynis.bin | json }}
{%- endfor %}

lynis/service/daemon-reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: lynis/service/unit/service
      - file: lynis/service/unit/timer

lynis/service/timer:
  service.running:
    - name: lynis.timer
    - enable: true
    - require:
      - cmd: lynis/service/daemon-reload
    - watch:
      - file: lynis/service/unit/timer

{%- else %}

lynis/service/timer:
  service.dead:
    - name: lynis.timer
    - enable: false

{%- for unit in ['timer', 'service'] %}
lynis/service/unit/{{ unit }}:
  file.absent:
    - name: /etc/systemd/system/lynis.{{ unit }}
    - require:
      - service: lynis/service/timer
{%- endfor %}

lynis/service/daemon-reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: lynis/service/unit/service
      - file: lynis/service/unit/timer

{%- endif %}
