require 'bundler/setup'
require 'librato-rack'

use Librato::Rack
run Proc.new { |env| [200, {"Content-Type" => 'text/html'}, ["Hello!"]]}