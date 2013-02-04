require 'thread'
require 'librato/metrics'

module Librato
  extend SingleForwardable
  def_delegators :tracker, :increment, :measure, :timing, :group

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
    DEFAULT_TRACKER = Librato

    def initialize(app, config = {})
      @app, @config = app, config
    end

    def call(env)
      # @metrics.check_worker
      record_header_metrics(env)
      response, duration = process_request(env)
      record_request_metrics(response.first, duration)
      response
    end

    private

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

    def tracker
      @tracker ||= @config[:tracker] || DEFAULT_TRACKER
    end

    def record_header_metrics(env)
      return unless env.keys.include?('HTTP_X_HEROKU_QUEUE_DEPTH')

      tracker.group 'rack.heroku' do |group|
        group.group 'queue' do |q|
          q.measure 'depth',     env['HTTP_X_HEROKU_QUEUE_DEPTH'].to_f
          q.timing  'wait_time', env['HTTP_X_HEROKU_QUEUE_WAIT_TIME'].to_f
        end
        group.measure 'dynos', env['HTTP_X_HEROKU_DYNOS_IN_USE'].to_f
      end
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
