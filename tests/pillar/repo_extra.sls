linux:
  system:
    enabled: true
    repo:
      mcp_extra_repo:
        source: "deb [arch=amd64] http://apt-mk.mirantis.com/{{ grains.get('oscodename') }}/ nightly extra"
        architectures: amd64
        key_url: "http://apt-mk.mirantis.com/public.gpg"
