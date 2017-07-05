{% from "telegraf/map.jinja" import telegraf_grains with context %}
{%- set remote_agent = telegraf_grains.telegraf.get('remote_agent', {}) %}

{%- if remote_agent.get('enabled', False) %}

{%- set remote_agent_label = pillar.get('docker', {}).get('client', {}).get('stack', {}).get('monitoring', {}).get('service', {}).get('remote_agent', {}).get('deploy', {}).get('labels', {}).get('com.mirantis.monitoring', 'remote_agent') %}
{%- set docker_ids = salt['cmd.run']("docker ps -q -f 'label=com.mirantis.monitoring=" + remote_agent_label + "'") %}

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
    - onchanges_in:
{%- for docker_id in docker_ids.split() %}
      - cmd: {{docker_id}}_remote_agent_reload
{%- endfor %}
    - require:
      - file: config_dir_remote_agent
    - context:
      agent: {{ remote_agent }}

{%- set remote_agent_inputs = {'input': remote_agent.input} %}
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
{%- if values.template is defined %}
      - salt://{{ values.template }}
{%- endif %}
      - salt://telegraf/files/input/{{ name }}.conf
      - salt://telegraf/files/input/generic.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - onchanges_in:
{%- for docker_id in docker_ids.split() %}
      - cmd: {{docker_id}}_remote_agent_reload
{%- endfor %}
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
    - onchanges_in:
{%- for docker_id in docker_ids.split() %}
      - cmd: {{docker_id}}_remote_agent_reload
{%- endfor %}
    - require:
      - file: config_d_dir_remote_agent
    - defaults:
        name: {{ name }}
        values: {{ values }}

{%- endfor %}

{%- for docker_id in docker_ids.split() %}
{{docker_id }}_remote_agent_reload:
  cmd.run:
    - name: docker kill -s SIGHUP {{ docker_id }}
{%- endfor %}
{%- endif %}
