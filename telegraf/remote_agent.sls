{% from "telegraf/map.jinja" import telegraf_grains with context %}
{%- set remote_agent = telegraf_grains.telegraf.get('remote_agent', {}) %}

{%- if remote_agent.get('enabled', False) %}

{%- set remote_agent_label = pillar.get('docker', {}).get('client', {}).get('stack', {}).get('monitoring', {}).get('service', {}).get('remote_agent', {}).get('deploy', {}).get('labels', {}).get('com.mirantis.monitoring', 'remote_agent') %}
{%- set docker_ids = salt['cmd.shell']("docker ps -q -f 'label=com.mirantis.monitoring=" + remote_agent_label + "' 2> /dev/null") %}

config_dir_remote_agent:
  file.directory:
    - name: {{remote_agent.dir.config}}
    - makedirs: True
    - mode: 755

config_d_dir_remote_agent:
  file.directory:
    - name: {{remote_agent.dir.config_d}}
    - makedirs: True
    - mode: 755
    - require:
      - file: config_dir_remote_agent

config_d_dir_remote_agent_clean:
  file.directory:
    - name: {{remote_agent.dir.config_d}}
    - clean: True
    - onchanges_in:
{%- for docker_id in docker_ids.split() %}
      - cmd: {{docker_id}}_remote_agent_reload
{%- endfor %}

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

{%- set remote_agent_inputs = {} %}
{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}
  {%- set remote_agent_input = node_grains.get('telegraf', {}).get('remote_agent', {}).get('input', {}) %}
  {%- if remote_agent_input %}
    {%- do salt['defaults.merge'](remote_agent_inputs, remote_agent_input) %}
  {%- endif %}
{%- endfor %}
{%- do salt['defaults.merge'](remote_agent_inputs, remote_agent.input) %}

{%- for name,values in remote_agent_inputs.iteritems() %}

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
    - require_in:
      - file: config_d_dir_remote_agent_clean
    - defaults:
        name: {{ name }}
{%- if values is mapping %}
        values: {{ values }}
{%- else %}
        values: {}
{%- endif %}

{%- endif %}

{%- endfor %}

{%- set remote_agent_outputs = {} %}
{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}
  {%- set remote_agent_output = node_grains.get('telegraf', {}).get('remote_agent', {}).get('output', {}) %}
  {%- if remote_agent_output %}
    {%- do salt['defaults.merge'](remote_agent_outputs, remote_agent_output) %}
  {%- endif %}
{%- endfor %}
{%- do salt['defaults.merge'](remote_agent_outputs, remote_agent.output) %}

{%- for name,values in remote_agent_outputs.iteritems() %}

output_{{ name }}_remote_agent:
  file.managed:
    - name: {{ remote_agent.dir.config_d }}/output-{{ name }}.conf
    - source:
{%- if values.template is defined %}
      - salt://{{ values.template }}
{%- endif %}
      - salt://telegraf/files/output/{{ name }}.conf
      - salt://telegraf/files/output/generic.conf
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
    - require_in:
      - file: config_d_dir_remote_agent_clean
    - defaults:
        name: {{ name }}
{%- if values is mapping %}
        values: {{ values }}
{%- else %}
        values: {}
{%- endif %}

{%- endfor %}

{%- for docker_id in docker_ids.split() %}
{{docker_id }}_remote_agent_reload:
  cmd.run:
    - name: docker kill -s SIGHUP {{ docker_id }}
{%- endfor %}
{%- endif %}
