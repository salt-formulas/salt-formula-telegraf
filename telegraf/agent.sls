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

{%- endfor %}

telegraf_grains_dir:
  file.directory:
  - name: /etc/salt/grains.d
  - mode: 700
  - makedirs: true
  - user: root

telegraf_grain:
  file.managed:
  - name: /etc/salt/grains.d/telegraf
  - source: salt://telegraf/files/telegraf.grain
  - template: jinja
  - mode: 600
  - require:
    - file: telegraf_grains_dir

telegraf_service:
  service.running:
    - name: telegraf
    - enable: True
    - watch:
      - file: telegraf_config

{%- endif %}
