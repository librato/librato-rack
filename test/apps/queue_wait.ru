require 'bundler/setup'
require 'librato-rack'

# Simulate the environment variables Heroku passes along
# with each request
#
class QueueWait
  def initialize(app)
    @app = app
  end

  def call(env)
    case env['PATH_INFO']
    when '/milli'
      env['HTTP_X_REQUEST_START'] = (Time.now.to_f * 1000).to_i.to_s
      sleep 0.005
    when '/micro'
      env['HTTP_X_REQUEST_START'] = (Time.now.to_f * 1000000).to_i.to_s
      sleep 0.01
    when '/queue_start'
      env['HTTP_X_QUEUE_START'] = (Time.now.to_f * 1000).to_i.to_s
      sleep 0.015
    when '/with_t'
      env['HTTP_X_REQUEST_START'] = "t=#{(Time.now.to_f * 1000000).to_i}".to_s
      sleep 0.02
    when '/with_period'
      env['HTTP_X_REQUEST_START'] = "%10.3f" % Time.now
      sleep 0.025
    when '/with_time_drift'
      env['HTTP_X_REQUEST_START'] = ((Time.now.to_f * 1000).to_i + 10).to_s # 10s in the future
      sleep 0.005
    end
    @app.call(env)
  end
end

use QueueWait
use Librato::Rack

def application(env)
  [200, {"Content-Type" => 'text/html'}, ["Hello!"]]
end

run method(:application)
