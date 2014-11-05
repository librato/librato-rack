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

      attr_accessor :user, :token, :autorun, :api_endpoint, :tracker,
                    :source_pids, :log_level, :log_prefix, :log_target,
                    :disable_rack_metrics, :flush_interval
      attr_reader :prefix, :source, :deprecations

      def initialize
        # set up defaults
        self.tracker = nil
        self.api_endpoint = Librato::Metrics.api_endpoint
        self.flush_interval = 60
        self.source_pids = false
        self.log_prefix = '[librato-rack] '
        @listeners = []
        @deprecations = []

        load_configuration
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

      # check environment variables and capture current state
      # for configuration
      def load_configuration
        self.user = ENV['LIBRATO_USER'] || ENV['LIBRATO_METRICS_USER']
        self.token = ENV['LIBRATO_TOKEN'] || ENV['LIBRATO_METRICS_TOKEN']
        self.autorun = detect_autorun
        self.prefix = ENV['LIBRATO_PREFIX'] || ENV['LIBRATO_METRICS_PREFIX']
        self.source = ENV['LIBRATO_SOURCE'] || ENV['LIBRATO_METRICS_SOURCE']
        self.log_level = ENV['LIBRATO_LOG_LEVEL'] || :info
        self.event_mode = ENV['LIBRATO_EVENT_MODE']
        check_deprecations
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

      def suites
        @suites ||= if ENV.has_key?('LIBRATO_SUITES')
          Suites.new(ENV['LIBRATO_SUITES'])
        else
          SuitesExcept.new(ENV['LIBRATO_SUITES_EXCEPT'])
        end
      end

      private

      def check_deprecations
        %w{USER TOKEN PREFIX SOURCE}.each do |item|
          if ENV["LIBRATO_METRICS_#{item}"]
            deprecate "LIBRATO_METRICS_#{item} will be removed in a future release, please use LIBRATO_#{item} instead."
          end
        end
      end

      def deprecate(message)
        @deprecations << message
      end

      def detect_autorun
        case ENV['LIBRATO_AUTORUN']
        when '0', 'FALSE'
          false
        when '1', 'TRUE'
          true
        else
          nil
        end
      end

      class Suites
        attr_reader :fields
        def initialize(value)
          @fields = value.to_s.split(/\s*,\s*/).map(&:to_sym)
        end

        def include?(field)
          fields.include?(field)
        end
      end

      class SuitesExcept < Suites
        def include?(field)
          !fields.include?(field)
        end
      end
    end
  end
end
