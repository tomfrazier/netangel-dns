Netangel::Dns.configure do
  config.host = '0.0.0.0'
  config.port = 5300
  config.daemon = false # TODO: Is this needed? Or how to handle production?
  config.upstream_dns = '8.8.8.8'
  config.enabled_blacklists = []
  config.enabled_whitelists = []
  config.enabled_safesearch = []
  config.git = { url: 'https://github.com/net-angel/netangel-blacklists.git', branch: 'master' }
  config.redis = { host: '127.0.0.1', port: 6379 }
  config.safesearch_lists = {
    'google'         => { list_name: 'ss-google',  ip: '216.239.38.120' },
    'youtube'        => { list_name: 'ss-youtube', ip: '216.239.38.119' },
    'youtube-strict' => { list_name: 'ss-youtube', ip: '216.239.38.120' },
    'bing'           => { list_name: 'ss-bing',    ip: '204.79.197.220' },
    'yahoo'          => { list_name: 'ss-yahoo',   ip: false            } # Just block yahoo search
  }
end
