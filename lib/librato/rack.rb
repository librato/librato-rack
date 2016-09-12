require 'thread'
require 'librato/metrics'

module Librato
  extend SingleForwardable
  def_delegators :tracker, :increment, :measure, :timing, :group

  def self.register_tracker(tracker)
    @tracker = tracker
  end

  def self.tracker
    @tracker ||= Librato::Rack::Tracker.new(Librato::Rack::Configuration.new)
  end
end

module Librato
  # Middleware for rack applications. Installs tracking hearbeat for
  # metric submission and tracks performance metrics.
  #
  # @example A basic rack app
  #   require 'rack'
  #   require 'librato-rack'
  #
  #   app = Rack::Builder.app do
  #     use Librato::Rack
  #     run lambda { |env| [200, {"Content-Type" => 'text/html'}, ["Hello!"]] }
  #   end
  #
  # @example Using a custom config object
  #   config = Librato::Rack::Configuration.new
  #   config.user = 'myuser@mysite.com'
  #   config.token = 'mytoken'
  #   …more configuration
  #
  #   use Librato::Rack, :config => config
  #   run MyApp
  #
  class Rack
    RECORD_RACK_BODY = <<-'EOS'
      group.increment 'total'
      group.timing    'time', duration, percentile: 95
      group.increment 'slow' if duration > 200.0
    EOS

    RECORD_RACK_STATUS_BODY = <<-'EOS'
      status_tags = { status: status }
      tracker.increment "rack.request.status", tags: status_tags
      tracker.timing "rack.request.status.time", duration, tags: status_tags
    EOS

    RECORD_RACK_METHOD_BODY = <<-'EOS'
      method_tags = { method: http_method.downcase! }
      tracker.increment "rack.request.method", tags: method_tags
      tracker.timing "rack.request.method.time", duration, tags: method_tags
    EOS

    attr_reader :config, :tracker

    def initialize(app, options={})
      @app = app
      @config = options.fetch(:config, Configuration.new)
      @tracker = @config.tracker || Tracker.new(@config)
      Librato.register_tracker(@tracker) # create global reference

      build_record_request_metrics_method
      build_record_header_metrics_method
      build_record_exception_method
    end

    def call(env)
      check_log_output(env) unless @log_target
      @tracker.check_worker
      record_header_metrics(env)
      response, duration = process_request(env)
      record_request_metrics(response.first, env["REQUEST_METHOD"], duration)
      response
    end

    private

    # this generally will only get called on the first request
    # it figures out the environment-appropriate logging outlet
    # and notifies config and tracker about it
    def check_log_output(env)
      return if @log_target
      if in_heroku_env?
        tracker.on_heroku = true
        default = ::Logger.new($stdout)
      else
        default = env['rack.errors'] || $stderr
      end
      @tracker.update_log_target(config.log_target ||= default)
      @log_target = config.log_target
    end

    def in_heroku_env?
      # don't have any custom http vars anymore, check if hostname is UUID
      Socket.gethostname =~ /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/i
    end

    def process_request(env)
      time = Time.now
      begin
        response = @app.call(env)
      rescue Exception => e
        record_exception(e)
        raise
      end
      duration = (Time.now - time) * 1000.0
      [response, duration]
    end


    # Dynamically construct :record_request_metrics method based on
    # configured metric suites
    def build_record_request_metrics_method
      body = "def record_request_metrics(status, http_method, duration)\n"
      body << "return if config.disable_rack_metrics\n"

      unless config.instance_of?(Librato::Rack::Configuration::SuitesNone)
        body << "tracker.group 'rack.request' do |group|\n"

        if tracker.suite_enabled?(:rack)
          body << RECORD_RACK_BODY
        end

        if tracker.suite_enabled?(:rack_status)
          body << RECORD_RACK_STATUS_BODY
        end

        if tracker.suite_enabled?(:rack_method)
          body << RECORD_RACK_METHOD_BODY
        end

        body << "end\n"
      end

      body << "end\n"

      instance_eval(body)
    end

    # Dynamically construct :record_header_metrics method based on
    # configured metric suites
    def build_record_header_metrics_method
      if tracker.suite_enabled?(:rack)
        define_singleton_method(:record_header_metrics) do |env|
          queue_start = env['HTTP_X_REQUEST_START'] || env['HTTP_X_QUEUE_START']
          if queue_start
            queue_start = queue_start.to_s.sub('t=', '').sub('.', '')
            case queue_start.length
            when 16 # microseconds
              wait = ((Time.now.to_f * 1000000).to_i - queue_start.to_i) / 1000.0
              tracker.timing 'rack.request.queue.time', wait, percentile: 95
            when 13 # milliseconds
              wait = (Time.now.to_f * 1000).to_i - queue_start.to_i
              tracker.timing 'rack.request.queue.time', wait, percentile: 95
            end
          end
        end
      else
        define_singleton_method(:record_header_metrics) do |env|
          # no-op
        end
      end
    end

    def build_record_exception_method
      if tracker.suite_enabled?(:rack)
        define_singleton_method(:record_exception) do |exception|
          return if config.disable_rack_metrics
          tracker.increment 'rack.request.exceptions'
        end
      else
        define_singleton_method(:record_exception) do |exception|
          # no-op
        end
      end
    end

  end
end

require 'librato/collector'
require 'librato/rack/configuration'
require 'librato/rack/errors'
require 'librato/rack/logger'
require 'librato/rack/tracker'
require 'librato/rack/validating_queue'
require 'librato/rack/version'
require 'librato/rack/worker'
