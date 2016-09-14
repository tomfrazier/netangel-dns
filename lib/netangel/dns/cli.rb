require 'thor'
require 'netangel/dns'
require 'netangel/dns/server'
require 'netangel/dns/client'
require 'netangel/dns/blacklist'
require 'netangel/dns/main'

module Netangel
  module Dns
    module Cli

      class Server < Thor
        desc 'start', 'Start DNS server'
        option :host,   aliases: '-h', type: :string
        option :port,   aliases: '-p', type: :numeric
        option :daemon, aliases: '-d', type: :boolean, default: false
        def start
          Netangel::Dns.load_config
          Netangel::Dns::Server.start(
            host:   options[:host],
            port:   options[:port],
            daemon: options[:daemon]
          )
        end

        desc 'stop', 'Stop DNS server'
        def stop
          Netangel::Dns::Server.stop
        end

        desc 'status', 'Server status'
        def status
          Netangel::Dns::Server.status
        end
      end

      class Client < Thor
        # Pre-hook before running any command
        def initialize( *args )
          super
          Netangel::Dns.load_config
          ::DataStore ||= Netangel::Dns::RedisApi.new
        end

        desc 'add [IP_ADDRESS]', 'Add a new client IP address for customization'
        def add( ip_address )
          Netangel::Dns::Client.add( ip_address )
        end

        desc 'get-ip-address [CLIENT_ID]', 'Return the IP address of a client'
        def get_ip_address( client_id )
          Netangel::Dns::Client.get_ip_address( client_id )
        end

        desc 'get-client-id [IP_ADDRESS]', 'Return the client ID of an IP address'
        def get_client_id( ip_address )
          Netangel::Dns::Client.get_client_id( ip_address )
        end

        desc 'reassign [CLIENT_ID]', 'Reassign a client to a different IP address'
        option :to, type: :string, required: true, banner: 'IP'
        def reassign( client_id )
          Netangel::Dns::Client.reassign( client_id, to: options[:to] )
        end

        desc 'list', 'List all clients with associated IP addresses'
        def list
          Netangel::Dns::Client.list
        end

        desc 'delete [IP or ID]', 'Delete client'
        def delete( argument )
          Netangel::Dns::Client.delete( argument )
        end

        desc 'blacklists [IP or ID]', 'View and manage blacklists assigned to a client'
        option :add,    aliases: '-a', type: :array, banner: 'BLACKLIST_NAME(S)]', default: []
        option :remove, aliases: '-r', type: :array, banner: 'BLACKLIST_NAME(S)]', default: []
        def blacklists( argument )
          Netangel::Dns::Client.blacklists( argument, add: options[:add], remove: options[:remove] )
        end

        desc 'whitelists [IP or ID]', 'View and manage whitelists assigned to a client'
        option :add,    aliases: '-a', type: :array, banner: 'WHITELIST_NAME(S)]', default: []
        option :remove, aliases: '-r', type: :array, banner: 'WHITELIST_NAME(S)]', default: []
        def whitelists( argument )
          Netangel::Dns::Client.whitelists( argument, add: options[:add], remove: options[:remove] )
        end

        desc 'safesearch [IP or ID]', 'View and manage safesearch settings for a client'
        option :add,    aliases: '-a', type: :array, banner: 'SAFESEARCH_SITE(S)]', default: []
        option :remove, aliases: '-r', type: :array, banner: 'SAFESEARCH_SITE(S)]', default: []
        def safesearch( argument )
          Netangel::Dns::Client.safesearch( argument, add: options[:add], remove: options[:remove] )
        end

        desc 'custom-blacklist [IP or ID]', 'View and manage custom blacklist sites for a client'
        option :add,    aliases: '-a', type: :array, banner: 'DOMAIN_NAME(S)]', default: []
        option :remove, aliases: '-r', type: :array, banner: 'DOMAIN_NAME(S)]', default: []
        def custom_blacklist( argument )
          Netangel::Dns::Client.custom_blacklist( argument, add: options[:add], remove: options[:remove] )
        end

        desc 'custom-whitelist [IP or ID]', 'View and manage custom whitelist sites for a client'
        option :add,    aliases: '-a', type: :array, banner: 'DOMAIN_NAME(S)]', default: []
        option :remove, aliases: '-r', type: :array, banner: 'DOMAIN_NAME(S)]', default: []
        def custom_whitelist( argument )
          Netangel::Dns::Client.custom_whitelist( argument, add: options[:add], remove: options[:remove] )
        end
      end

      # TODO: Do this!!
      class Safesearch < Thor
        # Pre-hook before running any command
        def initialize( *args )
          super
          Netangel::Dns.load_config
          ::DataStore ||= Netangel::Dns::RedisApi.new
        end

        desc 'add [IP_ADDRESS]', 'Add a new client IP address for customization'
        def add( ip_address )
          Netangel::Dns::Safesearch.add( ip_address )
        end

        desc 'reassign [CLIENT_ID]', 'Reassign a client to a different IP address'
        option :to, type: :string, required: true, banner: 'IP'
        def reassign( client_id )
          Netangel::Dns::Safesearch.reassign( client_id, to: options[:to] )
        end

        desc 'delete [IP or ID]', 'Delete client'
        def delete( argument )
          Netangel::Dns::Safesearch.delete( argument )
        end
      end

      class Blacklist < Thor
        desc 'remote-list', 'List available blacklists from remote server'
        option :git_url,    aliases: '-u', type: :string
        option :git_branch, aliases: '-b', type: :string
        def remote_list
          Netangel::Dns.load_config
          Netangel::Dns::Blacklist.remote_list(
            git_url:    options[:git_url],
            git_branch: options[:git_branch]
          )
        end

        desc 'list', 'List available local blacklists'
        def list
          Netangel::Dns::Blacklist.list
        end

        desc 'download [NAME]', 'Download blacklist'
        option :git_url,    aliases: '-u', type: :string
        option :git_branch, aliases: '-b', type: :string
        def download( list_name )
          Netangel::Dns.load_config
          Netangel::Dns::Blacklist.download( list_name,
            git_url:    options[:git_url],
            git_branch: options[:git_branch]
          )
        end

        desc 'enable [NAME]', 'Enable blacklist'
        def enable( list_name )
          Netangel::Dns.load_config
          Netangel::Dns::Blacklist.enable( list_name )
        end

        desc 'disable [NAME]', 'Disable blacklist'
        def disable( list_name )
          Netangel::Dns.load_config
          Netangel::Dns::Blacklist.disable( list_name )
        end

        desc 'delete [NAME]', 'Delete blacklist from system'
        def delete( list_name )
          Netangel::Dns::Blacklist.delete( list_name )
        end

        desc 'sync', 'Insert enabled blacklists into datastore'
        def sync
          Netangel::Dns.load_config
          Netangel::Dns::Blacklist.sync
        end
      end

      class Main < Thor
        # Pre-hook before running any command
        def initialize( *args )
          super
          ::Verbose ||= options[:verbose]
        end

        class_option :verbose, aliases: '-v', type: :boolean, default: false

        desc 'version', 'Display the program version'
        def version
          Netangel::Dns::Main.version
        end

        desc 'new [APP_NAME]', 'Create a new NetAngel DNS application'
        def new_app( app_name )
          Netangel::Dns::Main.new_app( app_name )
        end

        desc 'server', 'Start or stop the DNS server'
        subcommand 'server', Server

        desc 'client', 'Add, delete, and manage clients'
        subcommand 'client', Client

        desc 'safesearch', 'Add, delete, and manage safesearch IPs'
        subcommand 'safesearch', Safesearch

        desc 'blacklist', 'Download, sync, and manage blacklists'
        subcommand 'blacklist', Blacklist
      end
    end
  end
end
