require "fileutils"
require "sequel"

module Merb
  module Orms
    module Sequel

      class << self

        def config_file() Merb.root / "config" / "database.yml" end
        def sample_dest() Merb.root / "config" / "database.yml.sample" end
        def sample_source() File.dirname(__FILE__) / "database.yml.sample" end
      
        def copy_sample_config
          FileUtils.cp sample_source, sample_dest unless File.exists?(sample_dest)
        end
      
        def config
          @config ||= begin
            # Convert string keys to symbols
            full_config = Erubis.load_yaml_file(config_file)
            config = (Merb::Plugins.config[:merb_sequel] = {})
            (full_config[Merb.environment.to_sym] || full_config[Merb.environment] || full_config[:development]).each do |key, value|
              config[key.to_sym] = value
            end
            config
          end
        end
      
        # Database connects as soon as the gem is loaded
        def connect
          if File.exists?(config_file)
            Merb.logger.info!("Connecting to the '#{config[:database]}' database on '#{config[:host]}' using '#{config[:adapter]}' ...")
            connection = ::Sequel.connect(config_options(config))
            Merb.logger.error!("Connection Error: #{e}") unless connection
            connection
          else
            copy_sample_config
            Merb.logger.set_log(STDERR)
            Merb.logger.error! "No database.yml file found in #{Merb.root}/config."
            Merb.logger.error! "A sample file was created called config/database.yml.sample for you to copy and edit."
            exit(1)
          end
        end
        
        def config_options(config = {})
          options = {}
          
          # Use SQLite by default
          options[:adapter]  = (config[:adapter]  || "sqlite")
          # Use localhost as default host
          options[:host]     = (config[:host]     || "localhost")          
          # Default user is an empty string. Both username and user keys are supported.
          options[:user]     = (config[:username] || config[:user] || "")
          
          options[:password] = config[:password] || ""
          
          # Both encoding and charset options are supported, default is utf8
          options[:encoding] = (config[:encoding] || config[:charset] || "utf8")
          # Default database is hey_dude_configure_your_database
          options[:database] = config[:database] || "hey_dude_configure_your_database"
          # MSSQL support
          options[:db_type] = config[:db_type]  if config[:db_type]
          options[:logger]   = Merb.logger
          options
        end

      end
      
    end
    
  end

end
