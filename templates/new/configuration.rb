Netangel::Dns.configure do
  config.host = '0.0.0.0'
  config.port = 5300
  config.daemon = false
  config.upstream_dns = '8.8.8.8'
  config.enabled_blacklists = []
  config.enabled_whitelists = []
  config.enabled_safesearch = []
  config.git = { url: 'https://github.com/net-angel/netangel-blacklists.git', branch: 'master' }
  config.redis = { host: '127.0.0.1', port: 6379 }
end
