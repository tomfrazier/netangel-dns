require 'netangel/dns/celluloid_dns'
require 'netangel/dns/redis_api'

module Netangel
  module Dns

    class Server
      def self.start( host:, port:, daemon: )
        host = host || Netangel::Dns.config.host
        port = port || Netangel::Dns.config.port
        ::DataStore ||= Netangel::Dns::RedisApi.new
        puts 'Starting NetAngel DNS Server...'.green
        server = Netangel::Dns::CelluloidDns.new( listen: [[:udp, host, port], [:tcp, host, port]] )
        server.run
        sleep
      end
    end

  end
end
