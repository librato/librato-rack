require 'bundler/setup'
require 'librato-rack'

use Librato::Rack

def application(env)
  case env['PATH_INFO']
  when '/increment'
    Librato.increment :hits
  when '/measure'
    Librato.measure 'nodes', 3
  when '/timing'
    Librato.timing 'lookup.time', 2.3
  when '/timing_block'
    Librato.timing 'sleeper' do
      sleep 0.01
    end
  end
  [200, {"Content-Type" => 'text/html'}, ["Hello!"]]
end

run method(:application)