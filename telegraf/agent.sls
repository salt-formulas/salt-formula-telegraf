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

{%- set service_grains = {'telegraf': {'agent': {'input': {}}}} %}
{%- for service_name, service in pillar.items() %}
  {%- if service.get('_support', {}).get('telegraf', {}).get('enabled', False) %}
    {%- set grains_fragment_file = service_name+'/meta/telegraf.yml' %}
    {%- macro load_grains_file() %}{% include grains_fragment_file ignore missing %}{% endmacro %}
    {%- set grains_yaml = load_grains_file()|load_yaml %}
    {%- if grains_yaml is mapping %}
      {%- set service_grains = salt['grains.filter_by']({'default': service_grains}, merge={'telegraf': grains_yaml}) %}
    {%- endif %}
  {%- endif %}
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
  - defaults:
    service_grains: {{ service_grains|yaml }}
  - require:
    - file: telegraf_grains_dir

{%- set telegraf_input = service_grains.telegraf.agent.input %}
{%- for name,values in telegraf_input.iteritems() %}

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

telegraf_service:
  service.running:
    - name: telegraf
    - enable: True
    - watch:
      - file: telegraf_config

{%- endif %}
