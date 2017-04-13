telegraf:
  agent:
    enabled: true
    interval: 15
    round_interval: false
    metric_batch_size: 1000
    metric_buffer_limit: 10000
    collection_jitter: 2
    output:
      prometheus_client:
        bind:
          address: 127.0.0.1
          port: 9126
        engine: prometheus
