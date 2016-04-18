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
    env['HTTP_X_QUEUE_START'] = (Time.now.to_f * 1000).to_i.to_s
    @app.call(env)
  end
end

use QueueWait
use Librato::Rack

def application(env)
  case env['PATH_INFO']
  when '/status/204'
    [204, {"Content-Type" => 'text/html'}, ["Status 204!"]]
  when '/exception'
    raise 'exception raised!'
  when '/slow'
    sleep 0.3
    [200, {"Content-Type" => 'text/html'}, ["Slow request"]]
  else
    [200, {"Content-Type" => 'text/html'}, ["Hello!"]]
  end
end

run method(:application)
