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
    attr_reader :config, :tracker

    def initialize(app, options={})
      old_style = false
      if options.respond_to?(:log_level) # old-style single argument
        config = options
        old_style = true
      else
        config = options.fetch(:config, Configuration.new)
      end
      @app, @config = app, config
      @tracker = @config.tracker || Tracker.new(@config)
      Librato.register_tracker(@tracker) # create global reference

      if old_style
        @tracker.deprecate 'middleware setup no longer takes a single argument, use `use Librato::Rack :config => config` instead.'
      end
    end

    def call(env)
      check_log_output(env) unless @log_target
      @tracker.check_worker
      request_method = env["REQUEST_METHOD"]
      record_header_metrics(env)
      response, duration = process_request(env)
      record_request_metrics(response.first, request_method, duration)
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

    def record_header_metrics(env)
      queue_start = env['HTTP_X_REQUEST_START'] || env['HTTP_X_QUEUE_START']
      if queue_start
        queue_start = queue_start.to_s.gsub('t=', '').to_i
        case queue_start.to_s.length
        when 16 # microseconds
          wait = ((Time.now.to_f * 1000000).to_i - queue_start) / 1000.0
          tracker.timing 'rack.request.queue.time', wait
        when 13 # milliseconds
          wait = (Time.now.to_f * 1000).to_i - queue_start
          tracker.timing 'rack.request.queue.time', wait
        end
      end
    end

    def record_request_metrics(status, http_method, duration)
      return if config.disable_rack_metrics
      tracker.group 'rack.request' do |group|
        group.increment 'total'
        group.timing    'time', duration
        group.increment 'slow' if duration > 200.0

        group.group 'status' do |s|
          s.increment status
          s.increment "#{status.to_s[0]}xx"

          s.timing "#{status}.time", duration
          s.timing "#{status.to_s[0]}xx.time", duration
        end

        group.group 'method' do |m|
          http_method.downcase!
          m.increment http_method
          m.timing "#{http_method}.time", duration
        end
      end
    end

    def record_exception(exception)
      return if config.disable_rack_metrics
      tracker.increment 'rack.request.exceptions'
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
