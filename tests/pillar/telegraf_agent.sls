telegraf:
  agent:
    enabled: true
    interval: 15
    round_interval: false
    metric_batch_size: 1000
    metric_buffer_limit: 10000
    collection_jitter: 2
    flush_interval: 10
    flush_jitter: 2
    precision: ms
    logfile: etc/telegraf/log
    debug: true
    quiet: false
    hostname: hostname
    omit_hostname: false
    global_tags:
      user: $USER
      static_tag: global_tag_1
    output:
      prometheus_client:
        bind:
          address: 127.0.0.1
          port: 9126
        engine: prometheus
    input:
      cpu:
        totalcpu: totalcpu_value
        tags:
          cpu_tag_1: cpu_value_1
      disk:
        mountpoints: 2
        tags:
          disk_tag_1: disk_value_1
      diskio:
        skip_serial_number: false
        tags:
          diskio_tag_1: diskio_value_1
      docker:
        endpoint: endpoint_name
        tags:
          docker_tag_1: docker_value_1
      mem:
        tags:
          mem_tag_1: mem_value_1
      net:
        tags:
          net_tag_1: net_value_1
      netstat:
        tags:
          netstat_tag_1: netstat_value_1
      processes:
        tags:
          processes_tag_1: processes_value_1
      procstat:
        pid_file: pid_file_name
        tags:
          procstat_tag_1: procstat_value_1
      system:
        tags:
          system_tag_1: system_value_1
