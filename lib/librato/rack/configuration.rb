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
      EVENT_MODES = [:eventmachine, :synchrony]

      attr_accessor :user, :token, :api_endpoint, :tracker, :source_pids,
                    :log_level, :flush_interval, :log_target,
                    :disable_rack_metrics
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
        self.event_mode = ENV['LIBRATO_EVENT_MODE']
      end

      def event_mode
        @event_mode
      end

      # set event_mode, valid options are EVENT_MODES or
      # nil (the default) if not running in an evented context
      def event_mode=(mode)
        mode = mode.to_sym if mode
        # reject unless acceptable mode, allow for turning event_mode off
        if [*EVENT_MODES, nil].include?(mode)
          @event_mode = mode
        else
          # TODO log warning
        end
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