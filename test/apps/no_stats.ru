require 'bundler/setup'
require 'librato-rack'

config = Librato::Rack::Configuration.new
config.disable_rack_metrics = true

use Librato::Rack, :config => config

def application(env)
  case env['PATH_INFO']
  when '/exception'
    raise 'exception raised!'
  else
    [200, {"Content-Type" => 'text/html'}, ["Hello!"]]
  end
end

run method(:application)