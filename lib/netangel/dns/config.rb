module Netangel
  module Dns

    class Config
      attr_accessor :host
      attr_accessor :port
      attr_accessor :daemon
      attr_accessor :enabled_blacklists
      attr_accessor :enabled_whitelists
      attr_accessor :enabled_safesearch
      attr_accessor :git
      attr_accessor :redis
      attr_accessor :upstream_dns

      def initialize
        @enabled_blacklists = []
        @enabled_whitelists = []
        @enabled_safesearch = []
        @git = {}
        @redis = {}
      end
    end

  end
end
