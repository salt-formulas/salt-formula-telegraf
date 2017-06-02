include:
  {%- if pillar.telegraf.agent is defined %}
  - telegraf.agent
  {%- endif %}
  {%- if pillar.telegraf.remote_agent is defined %}
  - telegraf.remote_agent
  {%- endif %}
