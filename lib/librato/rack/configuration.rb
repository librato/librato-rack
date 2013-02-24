module Librato
  class Rack
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
      attr_accessor :user, :token, :api_endpoint, :tracker, :source_pids,
                    :log_level, :flush_interval, :log_target
      attr_reader :prefix, :source

      def initialize
        # set up defaults
        self.tracker = nil
        self.api_endpoint = Librato::Metrics.api_endpoint
        self.flush_interval = 60
        self.source_pids = false
        @listeners = []

        # check environment
        self.user = ENV['LIBRATO_USER'] || ENV['LIBRATO_METRICS_USER']
        self.token = ENV['LIBRATO_TOKEN'] || ENV['LIBRATO_METRICS_TOKEN']
        self.prefix = ENV['LIBRATO_PREFIX'] || ENV['LIBRATO_METRICS_PREFIX']
        self.source = ENV['LIBRATO_SOURCE'] || ENV['LIBRATO_METRICS_SOURCE']
        self.log_level = ENV['LIBRATO_LOG_LEVEL'] || :info
      end

      def explicit_source?
        !!@explicit_source
      end

      def prefix=(prefix)
        @prefix = prefix
        @listeners.each { |l| l.prefix = prefix }
      end

      def register_listener(listener)
        @listeners << listener
      end

      def source=(src)
        @source = src
        @explicit_source = !!@source
      end

      def dump
        fields = {}
        %w{user token log_level source prefix flush_interval source_pids}.each do |field|
          fields[field.to_sym] = self.send(field)
        end
        fields
      end

    end
  end
end