{% from "telegraf/map.jinja" import agent with context %}
{%- if agent.enabled %}

telegraf_packages:
  pkg.installed:
    - names: {{ agent.pkgs }}

telegraf_config:
  file.managed:
    - name: {{ agent.file.config }}
    - source: salt://telegraf/files/telegraf.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: telegraf_packages

{%- for name,values in agent.input.iteritems() %}

input_{{ name }}:
  file.managed:
    - name: {{ agent.dir.config }}/input-{{ name }}.conf
    - source: salt://telegraf/files/input/{{ name }}.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: telegraf_packages
    - watch_in:
      - service: telegraf_service
    - defaults:
        name: {{ name }}
        values: {{ values }}

{%- endfor %}

{%- for name,values in agent.output.iteritems() %}

output_{{ name }}:
  file.managed:
    - name: {{ agent.dir.config }}/output-{{ name }}.conf
    - source: salt://telegraf/files/output/{{ name }}.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: telegraf_packages
    - watch_in:
      - service: telegraf_service
    - defaults:
        name: {{ name }}
        values: {{ values }}

{%- if name == 'prometheus_client' %}

{%- if values.bind.address == '0.0.0.0' %}
{%- set address = grains['fqdn_ip4'][0] %}
{%- else %}
{%- set address = values.bind.address %}
{%- endif %}

prometheus_client_grain:
  grains.present:
    - name: prometheus_client
    - force: True
    - value:
        address: {{ address }}
        port: {{ values.bind.port }}

{%- endif %}

{%- endfor %}

telegraf_service:
  service.running:
    - name: telegraf
    - enable: True
    - watch:
      - file: telegraf_config

{%- endif %}
