require 'test_helper'
require 'rack/test'

# Tests for universal tracking for all request paths
#
class HerokuTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('test/apps/heroku.ru').first
  end

  def teardown
    # clear metrics before each run
    aggregate.delete_all
    counters.delete_all
  end

  def test_heroku_metrics
    get '/'
    assert_equal 1, aggregate['rack.heroku.queue.depth'][:count]
    assert_equal 1, aggregate['rack.heroku.queue.wait_time'][:count]
    assert_equal 1, aggregate['rack.heroku.dynos'][:count]
  end

  private

  def aggregate
    Librato.tracker.collector.aggregate
  end

  def counters
    Librato.tracker.collector.counters
  end

end
