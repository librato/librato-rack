require 'socket'

module Librato
  class Rack
    class Tracker
      extend Forwardable

      SOURCE_REGEX = /\A[-:A-Za-z0-9_.]{1,255}\z/

      def_delegators :collector, :increment, :measure, :timing, :group
      def_delegators :logger, :log

      attr_reader :config
      attr_accessor :on_heroku

      def initialize(config)
        @config = config
        collector.prefix = config.prefix
        config.register_listener(collector)
      end

      # start worker thread, one per process.
      # if this process has been forked from an one with an active
      # worker thread we don't need to worry about cleanup, the worker
      # thread will not pass with the fork
      def check_worker
        return if @worker # already running
        return if !should_start?
        log(:debug) { "config: #{config.dump}" }
        @pid = $$
        log(:debug) { ">> starting up worker for pid #{@pid}..." }

        @worker = Worker.new(:timer => config.event_mode)
        @worker.run_periodically(config.flush_interval) do
          flush
        end

        config.deprecations.each { |d| deprecate(d) }
      end

      # primary collector object used by this tracker
      def collector
        @collector ||= Librato::Collector.new
      end

      # log a deprecation message
      def deprecate(message)
        log :warn, "DEPRECATION: #{message}"
      end

      # send all current data to Metrics
      def flush
        log :debug, "flushing pid #{@pid} (#{Time.now}).."
        start = Time.now
        # thread safety is handled internally for stores
        queue = build_flush_queue(collector)
        queue.submit unless queue.empty?
        log(:trace) { "flushed pid #{@pid} in #{(Time.now - start)*1000.to_f}ms" }
      rescue Exception => error
        log :error, "submission failed permanently: #{error}"
      end

      # source including process pid if indicated
      def qualified_source
        config.source_pids ? "#{source}.#{$$}" : source
      end

      # change output stream for logging
      def update_log_target(target)
        logger.outlet = target
      end

      private

      # access to client instance
      def client
        @client ||= prepare_client
      end

      # use custom faraday adapter if running in evented context
      def custom_adapter
        case config.event_mode
        when :eventmachine
          :em_http
        when :synchrony
          :em_synchrony
        else
          nil
        end
      end

      def build_flush_queue(collector)
        queue = ValidatingQueue.new( :client => client, :source => qualified_source,
          :prefix => config.prefix, :skip_measurement_times => true )
        [collector.counters, collector.aggregate].each do |cache|
          cache.flush_to(queue)
        end
        queue.add 'rack.processes' => 1
        trace_queued(queue.queued) #if should_log?(:trace)
        queue
      end

      # trace metrics being sent
      def trace_queued(queued)
        require 'pp'
        log(:trace) { "Queued: " + queued.pretty_inspect }
      end

      def logger
        return @logger if @logger
        @logger = Logger.new(config.log_target)
        @logger.log_level = config.log_level
        @logger
      end

      def prepare_client
        client = Librato::Metrics::Client.new
        client.authenticate config.user, config.token
        client.api_endpoint = config.api_endpoint
        client.custom_user_agent = user_agent
        if custom_adapter
          client.faraday_adapter = custom_adapter
        end
        client
      end

      def ruby_engine
        return RUBY_ENGINE if Object.constants.include?(:RUBY_ENGINE)
        RUBY_DESCRIPTION.split[0]
      end

      def should_start?
        return false if @pid_checked == $$ # only check once per process
        @pid_checked = $$
        if !config.user || !config.token
          # don't show this unless we're debugging, expected behavior
          log :debug, 'halting: credentials not present.'
          false
        elsif qualified_source !~ SOURCE_REGEX
          log :warn, "halting: '#{qualified_source}' is an invalid source name."
          false
        elsif on_heroku && !config.explicit_source?
          log :warn, 'halting: source must be provided in configuration.'
          false
        else
          true
        end
      end

      def source
        @source ||= (config.source || Socket.gethostname).downcase
      end

      def user_agent
        ua_chunks = []
        ua_chunks << "librato-rack/#{Librato::Rack::VERSION}"
        ua_chunks << "(#{ruby_engine}; #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}; #{RUBY_PLATFORM})"
        ua_chunks.join(' ')
      end
    end
  end
end