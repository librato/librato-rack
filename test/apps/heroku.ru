require 'bundler/setup'
require 'librato-rack'

# Simulate the environment variables Heroku passes along
# with each request
#
class FakeHeroku
  def initialize(app)
    @app = app
  end

  def call(env)
    env['HTTP_X_HEROKU_QUEUE_DEPTH'] = rand(4)
    env['HTTP_X_HEROKU_QUEUE_WAIT_TIME'] = rand(0.1)
    env['HTTP_X_HEROKU_DYNOS_IN_USE'] = 2
    @app.call(env)
  end
end

use FakeHeroku
use Librato::Rack

def application(env)
  [200, {"Content-Type" => 'text/html'}, ["Hello!"]]
end

run method(:application)