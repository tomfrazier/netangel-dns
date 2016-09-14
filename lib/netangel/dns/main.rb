require 'netangel/dns/version'
require 'netangel/dns/generator'

module Netangel
  module Dns

    class Main
      def self.version
        Netangel::Dns::Utils.output( :version, Netangel::Dns::VERSION )
      end

      def self.new_app( app_name )
        app_class = app_name.camelize
        app_dir = app_name.underscore
        Netangel::Dns::Generator.create_dir( app_dir )
        FileUtils.cd( app_dir ) do
          Netangel::Dns::Generator.create_dir( 'lists' )
          FileUtils.cd( 'lists' ) do
            Netangel::Dns::Generator.create_dir( 'blacklists' )
            Netangel::Dns::Generator.create_dir( 'whitelists' )
            Netangel::Dns::Generator.create_dir( 'safesearch' )
          end
          Netangel::Dns::Generator.copy_file( :new, 'configuration.rb' )
          Netangel::Dns::Generator.copy_file( :new, 'Gemfile' )
          Netangel::Dns::Generator.run_command( 'bundle install' )
        end
      end
    end

  end
end
