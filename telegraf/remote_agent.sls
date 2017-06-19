{% from "telegraf/map.jinja" import telegraf_grains with context %}
{%- set remote_agent = telegraf_grains.telegraf.get('remote_agent', {}) %}

{%- if remote_agent.get('enabled', False) %}

config_dir_remote_agent:
  file.directory:
    - name: {{remote_agent.dir.config}}
    - makedirs: True
    - mode: 755

config_d_dir_remote_agent:
  file.directory:
    - name: {{remote_agent.dir.config_d}}
    - makedirs: True
    - clean: True
    - mode: 755
    - require:
      - file: config_dir_remote_agent

telegraf_config_remote_agent:
  file.managed:
    - name: {{ remote_agent.dir.config }}/telegraf.conf
    - source: salt://telegraf/files/telegraf.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - file: config_dir_remote_agent
    - context:
      agent: {{ remote_agent }}

{%- set remote_agent_inputs = {'input': {}} %}
{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}
  {%- set remote_agent_input = node_grains.get('telegraf', {}).get('remote_agent', {}).get('input', {}) %}
  {%- if remote_agent_input %}
    {%- set remote_agent_inputs = salt['grains.filter_by']({'default': remote_agent_inputs}, merge={'input': remote_agent_input}) %}
  {%- endif %}
{%- endfor %}

{%- for name,values in remote_agent_inputs.get('input', {}).iteritems() %}

{%- if values is not mapping or values.get('enabled', True) %}
input_{{ name }}_remote_agent:
  file.managed:
    - name: {{ remote_agent.dir.config_d }}/input-{{ name }}.conf
    - source:
      - salt://telegraf/files/input/{{ name }}.conf
      - salt://telegraf/files/input/generic.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - file: config_d_dir_remote_agent
    - defaults:
        name: {{ name }}
        values: {{ values }}

{%- endif %}

{%- endfor %}

{%- for name,values in remote_agent.get('output', {}).iteritems() %}

output_{{ name }}_remote_agent:
  file.managed:
    - name: {{ remote_agent.dir.config_d }}/output-{{ name }}.conf
    - source: salt://telegraf/files/output/{{ name }}.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - file: config_d_dir_remote_agent
    - defaults:
        name: {{ name }}
        values: {{ values }}

{%- endfor %}
{%- endif %}
