require 'bundler/setup'
require 'librato-rack'

use Librato::Rack

def application(env)
  case env['PATH_INFO']
  when '/tags'
    tags = { region: "us-east-1" }
    Librato.increment "requests", tags: tags
    Librato.timing "requests.time", 3, tags: tags
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
  when '/group'
    Librato.group 'did.a' do |g|
      g.increment 'thing'
      g.timing 'timing', 2.3
    end
  end
  [200, {"Content-Type" => 'text/html'}, ["Hello!"]]
end

run method(:application)
