module Librato::Rack
  # Holds configuration for Librato::Rack middleware to use.
  # Acquires some settings by default from environment variables, 
  # but this allows easy setting and overrides.
  #
  # @example
  #   config = Librato::Rack::Configuration.new
  #   config.user  = 'mimo@librato.com'
  #   config.token = 'mytoken'
  #   
  class Configuration
    attr_accessor :user, :token, :api_endpoint, :prefix, :source,
                  :source_pids, :log_level, :flush_interval
    
    def initialize(&block)
      # set up defaults
      self.api_endpoint = Librato::Metrics.api_endpoint
      self.flush_interval = 60
      
      # check environment
      self.user = ENV['LIBRATO_USER']
      self.token = ENV['LIBRATO_TOKEN']
      self.prefix = ENV['LIBRATO_PREFIX']
      self.source = ENV['LIBRATO_SOURCE']
      self.log_level = ENV['LIBRATO_LOG_LEVEL'] || :info
    end
    
  end
end