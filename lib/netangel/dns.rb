require 'colorize'
require 'active_support/inflector'
require 'pathname'
require 'netangel/dns/config'
require 'netangel/dns/utils'
require 'fileutils'

module Netangel
  module Dns
    extend self

    def root
      File.expand_path( '../../..', __FILE__ )
    end

    def template_path
      File.join( root, 'templates' )
    end

    def configure( &block )
      instance_eval( &block )
    end

    def config
      @config ||= Netangel::Dns::Config.new
    end

    def config_dir( dir = Pathname.new( '.' ) )
      app_config_dir = dir + 'configuration.rb'
      if dir.children.include?( app_config_dir )
        app_config_dir.expand_path
      else
        return nil if dir.expand_path.root?
        config_dir( dir.parent )
      end
    end

    def load_config
      configuration_file = config_dir&.to_s
      unless configuration_file
        abort 'Unable to locate "configuration.rb"'.red
      end
      load configuration_file
    end
  end
end
