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

        # TODO: Currently only support 'A' records!
        if resource_class == Resolv::DNS::Resource::IN::A
          domain_name.sub!( /^www\./, '' ) # Remove "www" from beginning of domain name

          ####################
          # Custom Whitelist #
          ####################

          if DataStore.in_list?( 'custom_whitelist', id: client_id, value: domain_name )
            puts "#{ip_address}\t#{domain_name}\t#{'TRUSTED!'.green}\tIn custom whitelist for client ID '#{client_id}'" if Verbose
            transaction.passthrough!( @resolver )
            return
          end

          # Default
          if DataStore.in_list?( 'custom_whitelist', id: 'default', value: domain_name )
            puts "#{ip_address}\t#{domain_name}\t#{'TRUSTED!'.green}\tIn default custom whitelist" if Verbose
            transaction.passthrough!( @resolver )
            return
          end

          ####################
          # Custom Blacklist #
          ####################

          if DataStore.in_list?( 'custom_blacklist', id: client_id, value: domain_name )
            puts "#{ip_address}\t#{domain_name}\t#{'DENIED!'.red}\tIn custom blacklist for client ID '#{client_id}'" if Verbose
            transaction.fail!( :NXDomain )
            return
          end

          # Default
          if DataStore.in_list?( 'custom_blacklist', id: 'default', value: domain_name )
            puts "#{ip_address}\t#{domain_name}\t#{'DENIED!'.red}\tIn default custom blacklist" if Verbose
            transaction.fail!( :NXDomain )
            return
          end

          ##############
          # Whitelists #
          ##############

          Netangel::Dns::config.enabled_whitelists.each do |whitelist|
            if DataStore.in_list?( 'whitelists', id: client_id, value: whitelist )
              if DataStore.in_list?( 'sites', id: whitelist, value: domain_name )
                puts "#{ip_address}\t#{domain_name}\t#{'TRUSTED!'.green}\tIn whitelist '#{whitelist}' for client ID '#{client_id}'" if Verbose
                transaction.passthrough!( @resolver )
                return
              end
            end

            # Default
            if DataStore.in_list?( 'whitelists', id: 'default', value: whitelist )
              if DataStore.in_list?( 'sites', id: whitelist, value: domain_name )
                puts "#{ip_address}\t#{domain_name}\t#{'TRUSTED!'.green}\tIn default whitelist '#{whitelist}'" if Verbose
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
                puts "#{ip_address}\t#{domain_name}\t#{'DENIED!'.red}\tIn blacklist '#{blacklist}' for client ID '#{client_id}'" if Verbose
                transaction.fail!( :NXDomain )
                return
              end
            end

            # Default
            if DataStore.in_list?( 'blacklists', id: 'default', value: blacklist )
              if DataStore.in_list?( 'sites', id: blacklist, value: domain_name )
                puts "#{ip_address}\t#{domain_name}\t#{'DENIED!'.red}\tIn default blacklist '#{blacklist}'" if Verbose
                transaction.fail!( :NXDomain )
                return
              end
            end
          end

          ##############
          # SafeSearch #
          ##############

          Netangel::Dns::config.safesearch_lists.each do |safesearch_name, safesearch_settings|
            safesearch_list_name = safesearch_settings[:list_name]
            if Netangel::Dns::config.enabled_safesearch.include?( safesearch_list_name )
              if DataStore.in_list?( 'safesearch', id: client_id, value: safesearch_name )
                if DataStore.in_list?( 'sites', id: safesearch_list_name, value: domain_name )
                  puts "#{ip_address}\t#{domain_name}\t#{'ENFORCED SAFESEARCH!'.blue}\tIn safesearch '#{safesearch_name}' for client ID '#{client_id}'" if Verbose
                  if safesearch_settings[:ip]
                    transaction.respond!( safesearch_settings[:ip] )
                  else # If there is no SafeSearch IP, just block the site
                    transaction.fail!( :NXDomain )
                  end
                  return
                end
              end

              # Default
              if DataStore.in_list?( 'safesearch', id: 'default', value: safesearch_name )
                if DataStore.in_list?( 'sites', id: safesearch_list_name, value: domain_name )
                  puts "#{ip_address}\t#{domain_name}\t#{'ENFORCED SAFESEARCH!'.blue}\tIn default safesearch '#{safesearch_name}'" if Verbose
                  if safesearch_settings[:ip]
                    transaction.respond!( safesearch_settings[:ip] )
                  else # If there is no SafeSearch IP, just block the site
                    transaction.fail!( :NXDomain )
                  end
                  return
                end
              end
            end
          end
        end

        # If the DNS query has gotten to this point, forward requst to upstream server
        puts "#{ip_address}\t#{domain_name}\tPASSTHROUGH" if Verbose
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


# How do I sync client_ip with device_id on the dashboard?
# How do I sync device preferences on dashboard with redis on DNS server?

# Feature request:  Rather than enabled_blacklists in config file, just use redis!

# Store redis client_id -> device_id on rails dashboard
# Job on rails dashboard to update "clients" on redis
# When rails updates preferences, update on redis too
# Job on rails dashboard to update preferences on redis (24-hours)?? OR Have a "loading-in" on redis startup
# Use redis SOLEY for device preferences on rails?  - That way there is no syncing!!!  :)
# NEED to get vpn server and dashboard in same LAN!!!

# Verify configuration file first and exit if no good!

# Support hard coded DNS entries (for things like netflix and pokemon go)

# Use custom IP for DNS resolution for blocked page!
# Blocked page that contains bypass button  and one that DOESN'T contain the button (maybe have the dashboard rails serve the page so can check settings?)
#   Or have the settings in Redis so that another web server can access settings.
#   Or heck, even have this gem serve a web server as well as a DNS server???
#   Or have a netangel-blocked-page repo?
#      the IP of whoever requested the blocked page could lookup client_id
#      or pass in http param?

# When the bypass button is clicked:
#   d


# Need to have DNS server know to allow that site through temporarily for that client.
#    Use EXPIRE in redis for this!!!!!
#    Before custom_whitelist check, have a temporary_whitelist check

# I like the idea of "netangel-blocked-page" repo that interacts with the same redis server as "netangel-dns"
# Maybe have it be optional for users (by default uses just IP address for resolving to blocked page, or NXdomain)
# Or maybe rather than another repo, have it be "netangel-dns", but have a different command for starting the server
#   like:     netangel-dns web-server start

# netangel-dns client blocked-page 127.0.0.1 --allow-bypass
# netangel-dns blocked-page allow-bypass 127.0.0.1
# netangel-dns blocked-page bypass --add 127.0.0.1

# netangel-dns blocked-page bypass-pin 127.0.0.1 --pin 1234
# netangel-dns blocked-page bypass 127.0.0.1
# netangel-dns blocked-page bypass-none  127.0.0.1

# netangel-dns blocked-page 127.0.0.1 bypass-pin --pin 1234
# netangel-dns blocked-page 127.0.0.1 bypass
# netangel-dns blocked-page 127.0.0.1 bypass-none

# netangel-dns blocked-page 127.0.0.1 --bypass pin --pin 1234
# netangel-dns blocked-page 127.0.0.1 --bypass true
# netangel-dns blocked-page 127.0.0.1 --bypass false
# netangel-dns blocked-page 127.0.0.1 --bypass password

# No bypass button               bypass-none
# Bypass button                  bypass
# Bypass button with PIN         bypass-pin
# Bypass button with sign in     bypass-password
# Bypass button with request     bypass-request

# netangel-dns blocked-page start -v
# netangel-dns blocked-page stop
# netangel-dns blocked-page server --start
# netangel-dns web-server start
