require 'celluloid/dns'

module Netangel
  module Dns

    class CelluloidDns < Celluloid::DNS::Server
      def process( domain_name, resource_class, transaction )
        @resolver ||= Celluloid::DNS::Resolver.new(
          [[:udp, Netangel::Dns.config.upstream_dns, 53],
           [:tcp, Netangel::Dns.config.upstream_dns, 53]]
        )
        ip_address = transaction&.options[:peer]
        client_id = DataStore.reverse_lookup( 'client', key: ip_address )

        # See https://github.com/celluloid/celluloid-dns/issues/13
        unless domain_name.encoding.to_s == 'UTF-8'
          puts "#{ip_address}\t#{domain_name}\tBad encoding (#{domain_name.encoding})".red
          transaction.fail!( :NXDomain )
          return
        end

        # TODO: Currently only support 'A' records
        if resource_class == Resolv::DNS::Resource::IN::A
          domain_name.sub!( 'www.', '' )

          ####################
          # Custom Whitelist #
          ####################

          if DataStore.in_list?( 'custom_whitelist', id: client_id, value: domain_name )
            puts "#{ip_address}\t#{domain_name}\t#{'TRUSTED!'.green}" if Verbose
            transaction.passthrough!( @resolver )
            return
          end

          ####################
          # Custom Blacklist #
          ####################

          if DataStore.in_list?( 'custom_blacklist', id: client_id, value: domain_name )
            puts "#{ip_address}\t#{domain_name}\t#{'DENIED!'.red}" if Verbose
            transaction.fail!( :NXDomain )
            return
          end

          ##############
          # Whitelists #
          ##############

          Netangel::Dns::config.enabled_whitelists.each do |whitelist|
            if DataStore.in_list?( 'whitelists', id: client_id, value: whitelist )
              if DataStore.in_list?( 'sites', id: whitelist, value: domain_name )
                puts "#{ip_address}\t#{domain_name}\t#{'TRUSTED!'.green}" if Verbose
                transaction.passthrough!( @resolver )
                return
              end
            end
          end

          ##############
          # Blacklists #
          ##############

          Netangel::Dns::config.enabled_blacklists.each do |blacklist|
            if DataStore.in_list?( 'blacklists', id: client_id, value: blacklist )
              if DataStore.in_list?( 'sites', id: blacklist, value: domain_name )
                puts "#{ip_address}\t#{domain_name}\t#{'DENIED!'.red}" if Verbose
                transaction.fail!( :NXDomain )
                return
              end
            end
          end

          ##############
          # SafeSearch #
          ##############

          Netangel::Dns::config.enabled_safesearch.each do |safesearch_list|
            if DataStore.in_list?( 'safesearch', id: client_id, value: safesearch_list )
              if DataStore.in_list?( 'sites', id: safesearch_list, value: domain_name )
                puts "#{ip_address}\t#{domain_name}\t#{'ENFORCED SAFESEARCH!'.blue}" if Verbose
                safesearch_ip = DataStore.find_safesearch_ip( safesearch_list )
                if safesearch_ip
                  transaction.respond!( safesearch_ip )
                else # If there is no SafeSearch IP, just block the site
                  transaction.fail!( :NXDomain )
                end
                return
              end
            end
          end
        end

        # If the DNS query has gotten to this point, forward requst to upstream server
        puts "#{ip_address}\t#{domain_name}" if Verbose
        transaction.passthrough!( @resolver )

      rescue ArgumentError => e
        puts 'Hit exception! ArgumentError.'.red
        puts domain_name
        puts e
        puts e.backtrace
      rescue Encoding::CompatibilityError => e
        puts 'Hit exception! Encoding::CompatibilityError.'.red
        puts domain_name
        puts e
        puts e.backtrace
      rescue Errno::EHOSTUNREACH => e
        puts 'Hit exception! Errno::EHOSTUNREACH.'.red
        puts domain_name
        puts e
        puts e.backtrace
      rescue Celluloid::DeadActorError => e
        puts 'Hit exception! Celluloid::DeadActorError. Killing process...'.red
        puts domain_name
        puts e
        puts e.backtrace
        `killall -9 ruby` # TODO: Need to figure out how to do this better!
      rescue StandardError => e
        puts 'Hit exception! Unhandled. Killing process...'.red
        puts domain_name
        puts e.class
        puts e
        puts e.backtrace
        `killall -9 ruby` # TODO: Need to figure out how to do this better!
      end
    end
  end
end


# INCR next_client_id
# HMSET client:1000 ip 192.168.5.4 google 1 youtube 0
# HSET clients 192.168.5.4 1000

# Default blacklists
# ALWAYS ON NO MATTER WHAT????

# How do I sync client_ip with device_id on the dashboard?
# How do I sync device preferences on dashboard with redis on DNS server?

# Rather than enabled_blacklists in config file, just use redis!

# Store redis client_id -> device_id on rails dashboard
# Job on rails dashboard to update "clients" on redis
# When rails updates preferences, update on redis too
# Job on rails dashboard to update preferences on redis (24-hours)?? OR Have a "loading-in" on redis startup
# Use redis SOLEY for device preferences on rails?  - That way there is no syncing!!!  :)
# NEED to get vpn server and dashboard in same LAN!!!
