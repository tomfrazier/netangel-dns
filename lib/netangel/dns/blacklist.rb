require 'netangel/dns/redis_api'
require 'json'

module Netangel
  module Dns

    class Blacklist
      def self.remote_list( git_url:, git_branch:, output: true )
        git_url    = git_url    || Netangel::Dns.config.git[:url]
        git_branch = git_branch || Netangel::Dns.config.git[:branch]
        puts "Fetching from #{git_url} [#{git_branch}]..." if output
        response = Netangel::Dns::Utils.download_github_file(
          git_url: git_url,
          git_branch: git_branch,
          path: 'index.json'
        )

        begin
          lists = JSON.parse( response )
        rescue
          abort 'Unable to parse index.json file!'.red
        end

        if output
          lists.each do |list|
            type_text = case list['type']
            when 'black'
              'BLACK'.light_black.bold
            when 'white'
              'WHITE'.white.bold
            when 'safesearch'
              'SAFESEARCH'.blue.bold
            else
              'UNKNOWN'
            end
            puts " - #{list['name'].to_s.ljust( 17 )} [type: #{type_text}]"
          end
        end

        lists
      end

      def self.list( output: true )
        Netangel::Dns.load_config
        types = ['blacklists', 'whitelists', 'safesearch']
        type_lists = {}
        types.each do |type|
          type_lists[type] ||= []
          config_method_name = "enabled_#{type}"
          lists = Netangel::Dns::Utils.run_command( "ls lists/#{type}", output: false )
          lists.each_line do |list|
            list = list.chomp
            enabled = Netangel::Dns.config.send( config_method_name ).include?( list )
            type_lists[type] << [list, enabled]

            if output
              type_text = case type
              when 'blacklists'
                'BLACK'.light_black.bold
              when 'whitelists'
                'WHITE'.white.bold
              when 'safesearch'
                'SAFESEARCH'.blue.bold
              else
                'UNKNOWN'
              end
              status_text = enabled ? 'ENABLED'.green : 'DISABLED'.red
              puts " - #{list}".ljust( 17 ) + "[#{status_text}]".ljust( 26 ) + "[type: #{type_text}]"
            end
          end
        end

        type_lists
      end

      def self.download( list_name, git_url:, git_branch: )
        git_url    = git_url    || Netangel::Dns.config.git[:url]
        git_branch = git_branch || Netangel::Dns.config.git[:branch]

        puts "Fetching from #{git_url} [#{git_branch}]..."

        remote_lists = Netangel::Dns::Blacklist.remote_list(
          git_url: git_url,
          git_branch: git_branch,
          output: false
        )

        response = Netangel::Dns::Utils.download_github_file(
          git_url: git_url,
          git_branch: git_branch,
          path: "#{list_name}/domains"
        )

        remote_list = remote_lists.find { |list| list['name'] == list_name }
        abort "Unable to find list in index.json!".red unless remote_list

        case remote_list['type']
        when 'black'
          File.write( "lists/blacklists/#{list_name}", response )
        when 'white'
          File.write( "lists/whitelists/#{list_name}", response )
        when 'safesearch'
          File.write( "lists/safesearch/#{list_name}", response )
        else
          File.write( "lists/blacklists/#{list_name}", response )
        end

        Netangel::Dns::Utils.output( :download, list_name )
        Netangel::Dns::Blacklist.list
      end

      def self.enable( list_name )
        if File.exist?( "lists/blacklists/#{list_name}" )
          config_lists = Netangel::Dns.config.enabled_blacklists
          attribute_name = 'enabled_blacklists'
        elsif File.exist?( "lists/whitelists/#{list_name}" )
          config_lists = Netangel::Dns.config.enabled_whitelists
          attribute_name = 'enabled_whitelists'
        elsif File.exist?( "lists/safesearch/#{list_name}" )
          config_lists = Netangel::Dns.config.enabled_safesearch
          attribute_name = 'enabled_safesearch'
        else
          abort "'#{list_name}' has not been downloaded yet!".red
        end

        unless config_lists.include?( list_name )
          config_lists = config_lists + [list_name]
          Netangel::Dns::Generator.modify_config( attribute: attribute_name, value: config_lists )
        end

        Netangel::Dns::Utils.output( :enable, list_name )
        Netangel::Dns::Blacklist.list
      end

      def self.disable( list_name )
        if File.exist?( "lists/blacklists/#{list_name}" )
          config_lists = Netangel::Dns.config.enabled_blacklists
          attribute_name = 'enabled_blacklists'
        elsif File.exist?( "lists/whitelists/#{list_name}" )
          config_lists = Netangel::Dns.config.enabled_whitelists
          attribute_name = 'enabled_whitelists'
        elsif File.exist?( "lists/safesearch/#{list_name}" )
          config_lists = Netangel::Dns.config.enabled_safesearch
          attribute_name = 'enabled_safesearch'
        else
          abort "'#{list_name}' has not been downloaded yet!".red
        end

        if config_lists.include?( list_name )
          config_lists.delete( list_name )
          Netangel::Dns::Generator.modify_config( attribute: attribute_name, value: config_lists )
        end

        Netangel::Dns::Utils.output( :disable, list_name )
        Netangel::Dns::Blacklist.list
      end

      def self.delete( list_name )
        Netangel::Dns.load_config
        Netangel::Dns::Blacklist.disable( list_name )
        File.delete( "lists/blacklists/#{list_name}" ) if File.exist?( "lists/blacklists/#{list_name}" )
        File.delete( "lists/whitelists/#{list_name}" ) if File.exist?( "lists/whitelists/#{list_name}" )
        File.delete( "lists/safesearch/#{list_name}" ) if File.exist?( "lists/safesearch/#{list_name}" )
        Netangel::Dns::Utils.output( :delete, list_name )
        Netangel::Dns::Blacklist.list
      end

      def self.sync
        puts 'Syncing enabled blacklists with datastore...'
        redis_host = Netangel::Dns.config.redis[:host] || '127.0.0.1'
        redis_port = Netangel::Dns.config.redis[:port] || 6379
        types = ['blacklists', 'whitelists', 'safesearch']

        types.each do |type|
          config_method_name = "enabled_#{type}"
          Netangel::Dns.config.send( config_method_name ).each do |list_name|
            random_string = Netangel::Dns::Utils.generate_random_string
            protocol_filename = "/tmp/netangel-dns-sync-#{random_string}"
            Netangel::Dns::Utils.output( :write, list_name )
            File.open( protocol_filename, 'w' ) do |protocol_file|
              protocol_file << Netangel::Dns::Utils.generate_redis_protocol( 'DEL', "sites:#{list_name}" )
              File.foreach( "lists/#{type}/#{list_name}" ) do |line|
                domain = line.strip
                next if domain.empty?
                protocol_file << Netangel::Dns::Utils.generate_redis_protocol( 'SADD', "sites:#{list_name}", domain )
              end
            end

            # Redis Mass Insertion
            # See: http://redis.io/topics/mass-insert
            command = "cat #{protocol_filename} | redis-cli -h #{redis_host} -p #{redis_port} --pipe"
            Netangel::Dns::Utils.output( :run, command )
            Netangel::Dns::Utils.run_command( command )
          end
        end
      end
    end
  end
end
