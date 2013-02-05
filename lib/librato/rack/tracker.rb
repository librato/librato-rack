module Librato
  class Rack
    class Tracker
      extend Forwardable

      def_delegators :collector, :increment, :measure, :timing, :group

      attr_reader :config

      def initialize(config = Configuration.new)
        @config = config
      end

      # # if this process isn't running a worker yet, start it up!
      # # for forking servers this may happen a while after the server
      # # is restarted for some processes, generally when they serve
      # # their first request
      # def check_worker
      #   if @pid != $$
      #     start_worker
      #   end
      # end

      # primary collector object used by this tracker
      def collector
        @collector ||= Librato::Collector.new
      end

      # # send all current data to Metrics
      # def flush
      #   log :debug, "flushing pid #{@pid} (#{Time.now}).."
      #   start = Time.now
      #   queue = flush_queue
      #   # thread safety is handled internally for both stores
      #   counters.flush_to(queue)
      #   aggregate.flush_to(queue)
      #   # trace_queued(queue.queued) if should_log?(:trace)
      #   queue.submit unless queue.empty?
      #   log :trace, "flushed pid #{@pid} in #{(Time.now - start)*1000.to_f}ms"
      # rescue Exception => error
      #   log :error, "submission failed permanently: #{error}"
      # end
      #
      # # run once during Rails startup sequence
      # def setup(app)
      #   check_config
      #   trace_settings if should_log?(:debug)
      #   return unless should_start?
      #   if app_server == :other
      #     log :info, "starting up..."
      #   else
      #     log :info, "starting up with #{app_server}..."
      #   end
      #   @pid = $$
      #   app.middleware.use Librato::Rack::Middleware
      #   start_worker unless forking_server?
      # end
      #
      # # start the worker thread, one is needed per process.
      # # if this process has been forked from an one with an active
      # # worker thread we don't need to worry about cleanup as only
      # # the forking thread is copied.
      # def start_worker
      #   return if @worker # already running
      #   @pid = $$
      #   log :debug, ">> starting up worker for pid #{@pid}..."
      #   @worker = Thread.new do
      #     worker = Worker.new
      #     worker.run_periodically(self.flush_interval) do
      #       flush
      #     end
      #   end
      # end
      #
      # private
      #
      # # access to client instance
      # def client
      #   @client ||= prepare_client
      # end
      #
      # def flush_queue
      #   ValidatingQueue.new(
      #     :client => client,
      #     :source => qualified_source,
      #     :prefix => self.prefix,
      #     :skip_measurement_times => true )
      # end
      #
      # def log(level, msg)
      #   # TODO
      # end
      #
      # def prepare_client
      #   #check_config
      #   client = Librato::Metrics::Client.new
      #   client.authenticate user, token
      #   client.api_endpoint = @api_endpoint if @api_endpoint
      #   client.custom_user_agent = user_agent
      #   client
      # end
      #
      # def ruby_engine
      #   return RUBY_ENGINE if Object.constants.include?(:RUBY_ENGINE)
      #   RUBY_DESCRIPTION.split[0]
      # end
      #
      # def should_start?
      #   if !self.user || !self.token
      #     # don't show this unless we're debugging, expected behavior
      #     log :debug, 'halting: credentials not present.'
      #     false
      #   elsif qualified_source !~ SOURCE_REGEX
      #     log :warn, "halting: '#{qualified_source}' is an invalid source name."
      #     false
      #   elsif !explicit_source && on_heroku
      #     log :warn, 'halting: source must be provided in configuration.'
      #     false
      #   else
      #     true
      #   end
      # end
      #
      # def user_agent
      #   ua_chunks = []
      #   ua_chunks << "librato-rails/#{Librato::Rails::VERSION}"
      #   ua_chunks << "(#{ruby_engine}; #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}; #{RUBY_PLATFORM}; #{app_server})"
      #   ua_chunks.join(' ')
      # end

    end
  end
end