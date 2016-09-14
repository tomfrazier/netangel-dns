require 'netangel/dns/redis_api'

module Netangel
  module Dns

    class Client
      def self.add( ip_address )
        abort "IP #{ip_address} has already been added!".red if DataStore.reverse_lookup( 'client', key: ip_address )
        client_id = DataStore.increment_id( 'client' )
        DataStore.add( 'client', id: client_id, key: 'ip', value: ip_address )
        puts client_id
      end

      def self.get_ip_address( client_id )
        puts DataStore.lookup( 'client', id: client_id, key: 'ip' )
      end

      def self.get_client_id( ip_address )
        puts DataStore.reverse_lookup( 'client', key: ip_address )&.to_i
      end

      def self.reassign( client_id, to: )
        original_ip_address = DataStore.lookup( 'client', id: client_id, key: 'ip' )
        abort "Client ID #{client_id} doesn't exist!".red unless original_ip_address
        other_client_id = DataStore.reverse_lookup( 'client', key: to )
        DataStore.delete( 'client', id: other_client_id, key: 'ip' )
        # TODO: Add associated_lists for deletion?? and update associatd_lists??
        DataStore.delete( 'client', id: client_id, key: 'ip' )
        DataStore.add(    'client', id: client_id, key: 'ip', value: to )
      end

      def self.list
        clients = DataStore.lookup_all( 'client' )
        clients.each do |ip_address, client_id|
          puts "#{client_id.to_s.ljust( 6 )} #{ip_address}"
        end
      end

      def self.delete( argument )
        client_id = argument_to_client_id( argument )
        DataStore.delete( 'client', id: client_id, key: 'ip',
          associated_lists: ['blacklists', 'whitelists', 'safesearch', 'custom_blacklist', 'custom_whitelist']
        )
      end

      def self.blacklists( argument, add:, remove: )
        # TODO: Check to see if blacklist attempting to add/remove actually exists!
        list_update( argument, list_name: 'blacklists', add: add, remove: remove )
      end

      def self.whitelists( argument, add:, remove: )
        list_update( argument, list_name: 'whitelists', add: add, remove: remove )
      end

      def self.safesearch( argument, add:, remove: )
        list_update( argument, list_name: 'safesearch', add: add, remove: remove )
      end

      def self.custom_blacklist( argument, add:, remove: )
        list_update( argument, list_name: 'custom_blacklist', add: add, remove: remove )
      end

      def self.custom_whitelist( argument, add:, remove: )
        list_update( argument, list_name: 'custom_whitelist', add: add, remove: remove )
      end

      private

      def self.argument_to_client_id( argument )
        if argument.ip_address?
          client_id = DataStore.reverse_lookup( 'client', key: argument )
        else
          client_id = argument
        end
        client_id
      end

      def self.list_update( argument, list_name:, add:, remove: )
        type_lists = Netangel::Dns::Blacklist.list( output: false )
        client_id = argument_to_client_id( argument )

        add.each do |name|
          found = type_lists[list_name]&.find { |entity, enabled| ( entity == name ) && enabled }
          abort "Cannot add '#{name}' to #{list_name}! It has either not been downloaded yet or is not enabled.".red unless found
          DataStore.add_to_list( list_name, id: client_id, value: name )
        end

        remove.each do |name|
          DataStore.remove_from_list( list_name, id: client_id, value: name )
        end

        all = DataStore.list( list_name, id: client_id )
        if all.empty?
          puts "No items in the #{list_name} for #{argument}. Use \"-a\" to add something."
        else
          puts all
        end
      end
    end
  end
end
