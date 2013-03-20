require 'bundler/setup'
require 'librato-rack'

config = Librato::Rack::Configuration.new
config.prefix = 'deprecated'

# old-style single-argument assignment
use Librato::Rack, config

def application(env)
  [200, {"Content-Type" => 'text/html'}, ["Hello!"]]
end

run method(:application)