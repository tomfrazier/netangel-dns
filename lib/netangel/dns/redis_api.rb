require 'redis'
require 'active_support/inflector'

module Netangel
  module Dns

    class RedisApi
      def initialize
        host = Netangel::Dns.config.redis[:host] || '127.0.0.1'
        port = Netangel::Dns.config.redis[:port] || 6379
        @server = Redis.new( host: host, port: port )
      end

      def increment_id( name )
        @server.incr( "next_#{name}_id" )&.to_i
      end

      def add( name, id:, key:, value: )
        @server.hmset( "#{name.singularize}:#{id}", key, value )
        @server.hset( name.pluralize, value, id )
      end

      def delete( name, id:, key:, associated_lists: [] )
        value = lookup( name, id: id, key: key )
        @server.del( "#{name.singularize}:#{id}" )
        @server.hdel( name.pluralize, value )
        associated_lists.each do |associated_list|
          @server.del( "#{associated_list}:#{id}" )
        end
      end

      def lookup_all( name )
        @server.hgetall( name.pluralize )
      end

      def lookup( name, id:, key: )
        @server.hget( "#{name.singularize}:#{id}", key )
      end

      def reverse_lookup( name, key: )
        @server.hget( name.pluralize, key )
      end

      def list( name, id: )
        @server.smembers( "#{name}:#{id}" )
      end

      def add_to_list( name, id:, value: )
        @server.sadd( "#{name}:#{id}", value )
      end

      def remove_from_list( name, id:, value: )
        @server.srem( "#{name}:#{id}", value )
      end

      def in_list?( name, id:, value: )
        @server.sismember( "#{name}:#{id}", value )
      end
    end
  end
end
