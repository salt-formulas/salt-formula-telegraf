{% from "telegraf/map.jinja" import agent, service_grains with context %}
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

{%- set telegraf_input = service_grains.telegraf.agent.input %}

{%- for name,values in telegraf_input.iteritems() %}

{%- if values is not mapping or values.get('enabled', True) %}
input_{{ name }}:
  file.managed:
    - name: {{ agent.dir.config }}/input-{{ name }}.conf
    - source:
      - salt://telegraf/files/input/{{ name }}.conf
      - salt://telegraf/files/input/generic.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: telegraf_packages
    {%- if not grains.get('noservices', False)%}
    - watch_in:
      - service: telegraf_service
    {%- endif %}
    - defaults:
        name: {{ name }}
        values: {{ values }}

{%- if name in ('docker', 'haproxy') %}
telegraf_user_in_group_{{ name }}:
  user.present:
    - name: telegraf
    - optional_groups:
      - {{ name }}
    - require:
      - pkg: telegraf_packages
{%- endif %}

{%- else %}
input_{{name }}:
  file.absent:
    - name: {{ agent.dir.config }}/input-{{ name }}.conf
    - require:
      - pkg: telegraf_packages
    {%- if not grains.get('noservices', False)%}
    - watch_in:
      - service: telegraf_service
    {%- endif %}
{%- endif %}

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
    {%- if not grains.get('noservices', False)%}
    - watch_in:
      - service: telegraf_service
    {%- endif %}
    - defaults:
        name: {{ name }}
        values: {{ values }}

{%- endfor %}

{%- if not grains.get('noservices', False)%}

telegraf_service:
  service.running:
    - name: telegraf
    - enable: True
    - watch:
      - file: telegraf_config

{%- endif %}

{%- endif %}
