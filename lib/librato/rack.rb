require 'thread'
require 'librato/metrics'

module Librato
  extend SingleForwardable
  def_delegators :tracker, :increment, :measure, :timing, :group

  def self.register_tracker(tracker)
    @tracker = tracker
  end

  def self.tracker
    @tracker ||= Librato::Rack::Tracker.new
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
  #     run lambda { |env| [200, {"Content-Type" => 'text/html'}, ["Hello!"]]}
  #   end
  #
  class Rack
    attr_reader :config, :tracker

    def initialize(app, config = Configuration.new)
      @app, @config = app, config
      @tracker = Tracker.new(@config)
      Librato.register_tracker(@tracker) # create global reference
    end

    def call(env)
      check_log_output(env)
      @tracker.check_worker
      record_header_metrics(env)
      response, duration = process_request(env)
      record_request_metrics(response.first, duration)
      response
    end

    private

    def check_log_output(env)
      return if @log_target
      if env.keys.include?('HTTP_X_HEROKU_QUEUE_DEPTH') # on heroku
        tracker.on_heroku = true
        default = ::Logger.new($stdout)
      else
        default = env['rack.errors'] || $stderr
      end
      config.log_target ||= default
      @log_target = config.log_target
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
      # TODO: track generalized queue wait
    end

    def record_request_metrics(status, duration)
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
      end
    end

    def record_exception(exception)
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
