require 'thread'
require 'librato/metrics'

module Librato
  extend SingleForwardable
  def_delegators :collector, :increment, :measure, :timing, :group

  def self.collector
    @collector ||= Librato::Collector.new
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
      time = Time.now

      begin
        response = @app.call(env)
      rescue Exception => e
        record_exception(e)
        raise
      end

      duration = (Time.now - time) * 1000.0
      record_request_metrics(response.first, duration)
      response
    end

    private

    def tracker
      @tracker ||= @config[:tracker] || DEFAULT_TRACKER
    end

    def record_header_metrics(env)
      return unless env.keys.include?('HTTP_X_HEROKU_QUEUE_DEPTH')

      # @metrics.group 'rack.heroku' do |group|
      #   group.measure 'queue.depth',     env['HTTP_X_HEROKU_QUEUE_DEPTH'].to_f
      #   group.timing  'queue.wait_time', env['HTTP_X_HEROKU_QUEUE_WAIT_TIME'].to_f
      #   group.measure 'queue.dynos',     env['HTTP_X_HEROKU_DYNOS_IN_USE'].to_f
      # end
    end

    def record_request_metrics(status, duration)
      tracker.group 'rack.request' do |group|
        group.increment 'total'
        group.timing    'time', duration
        # group.increment 'slow' if duration > 200.0

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
require 'librato/rack/worker'
require 'librato/rack/validating_queue'
require 'librato/rack/version'
