require 'test_helper'
require 'rack/test'

# Tests for universal tracking for all request paths
#
class NoStatsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('test/apps/no_stats.ru').first
  end

  def teardown
    # clear metrics before each run
    aggregate.delete_all
    counters.delete_all
  end

  def test_no_standard_counters
    get '/'
    assert last_response.ok?

    assert_equal nil, counters["rack.request.total"]
    assert_equal nil, counters["rack.request.status.200"]
    assert_equal nil, counters["rack.request.status.2xx"]
  end

  def test_no_standard_measures
    get '/'
    assert last_response.ok?

    assert_equal nil, aggregate["rack.request.time"]
  end

  def test_dont_track_exceptions
    begin
      get '/exception'
    rescue RuntimeError => e
      raise unless e.message == 'exception raised!'
    end
    assert_equal nil, counters["rack.request.exceptions"]
  end

  private

  def aggregate
    Librato.tracker.collector.aggregate
  end

  def counters
    Librato.tracker.collector.counters
  end

end
