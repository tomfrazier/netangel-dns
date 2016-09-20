require 'open3'
require 'net/http'
require 'json'
require 'resolv'

module Netangel
  module Dns
    class Utils

      # Runs a command.
      #
      # @param command [String] the command to run
      # @param output [Boolean] to show command stdout or not
      # @raise [SystemExit] abort the program if command failed
      # @return [String] the output (stdout) of running the command
      def self.run_command( command, output: true )
        stdout, stderr, status = Open3.capture3( command )
        unless status.success?
          abort "Command: '#{command}' failed! #{stdout.chomp} #{stderr.chomp}".red
        end
        puts stdout if output
        stdout
      end

      def self.output( type, text = '' )
        puts "#{type.to_s.rjust( 12 ).green.bold}  #{text}"
      end

      def self.download_github_file( git_url:, git_branch:, path: )
        path_array = path.split( '/' )
        filename = path_array.pop
        directory = path_array.join( '/' )
        git_data = /github\.com\/(.*)\/(.*)\.git/.match( git_url )
        owner = git_data[1]
        repo  = git_data[2]

        unless git_data[1] && git_data[2]
          abort "Git URL (#{git_url}) is not valid! Must be an HTTPS GitHub URL with '.git' on the end.".red
        end

        begin
          response = Net::HTTP.get( URI( "https://api.github.com/repos/#{owner}/#{repo}/contents/#{directory}?ref=#{git_branch}" ) )
          json = JSON.parse( response )
          entry = json.find { |entry| entry['name'] == filename }
          abort "Unable to find #{path}".red unless entry

          Net::HTTP.get( URI( entry['download_url'] ) )
        rescue
          abort 'Unable to download file! Check Git URL.'.red
        end
      end

      # Taken from http://redis.io/topics/mass-insert
      def self.generate_redis_protocol( *command )
        protocol = ''
        protocol << '*' + command.length.to_s + "\r\n"
        command.each do |argument|
          protocol << '$' + argument.to_s.bytesize.to_s + "\r\n"
          protocol << argument.to_s + "\r\n"
        end
        protocol
      end

      # Taken from http://stackoverflow.com/a/3572953/4681454
      def self.generate_random_string( length = 10 )
        ( 36 ** ( length - 1 ) + rand( 36 ** length - 36 ** ( length - 1) ) ).to_s( 36 )
      end
    end
  end
end

class String
  def ip_address?
    !!( self =~ Resolv::IPv4::Regex )
  end

  # Taken from http://stackoverflow.com/a/2095512/4681454
  def numeric?
    true if Float self rescue false
  end
end

class Fixnum
  def ip_address?
    false
  end
end

class Numeric
  def numeric?
    true
  end
end
