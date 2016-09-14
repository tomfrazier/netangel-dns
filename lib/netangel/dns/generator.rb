module Netangel
  module Dns
    class Generator

      def self.create_dir( dir )
        Netangel::Dns::Utils.output( :create, dir )
        begin
          FileUtils.mkdir( dir )
        rescue Errno::EEXIST
          abort "Directory '#{dir}' already exists!".red
        end
      end

      def self.copy_file( type, source, destination = '.' )
        Netangel::Dns::Utils.output( :create, source )
        FileUtils.cp( File.join( Netangel::Dns.template_path, "#{type}/#{source}" ), destination )
      end

      def self.run_command( command )
        Netangel::Dns::Utils.output( :run, command )
        Netangel::Dns::Utils.run_command( command )
      end

      def self.modify_config( attribute:, value: )
        config_file = File.read( Netangel::Dns.config_dir )
        config_lines = config_file.split( "\n" )

        if config_file.include?( attribute )
          inside_block = false
          config_lines.map! do |line|
            inside_block = true  if line.include?( 'Netangel::Dns.configure' )
            inside_block = false if line.include?( 'end' )
            if inside_block && line.include?( "config.#{attribute}" )
              line = "  config.#{attribute} = #{value}"
            end
            line
          end
        else # Config file doesn't include attribute yet!
          start_of_block = 0
          config_lines.each_with_index do |line, index|
            if line.include?( 'Netangel::Dns.configure' )
              start_of_block = index
              break
            end
          end
          config_lines.insert( start_of_block + 1, "  config.#{attribute} = #{value}" )
        end

        File.write( Netangel::Dns.config_dir, config_lines.join( "\n" ) )
      end

    end
  end
end
