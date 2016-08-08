require 'test_helper'
require 'rack/test'

# Tests for universal tracking for all request paths
#
class RequestTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('test/apps/basic.ru').first
  end

  def teardown
    # clear metrics before each run
    aggregate.delete_all
    counters.delete_all
  end

  def test_increment_total_and_status
    get '/'
    assert last_response.ok?
    assert_equal 1, counters["rack.request.total"]
    assert_equal 1, counters["rack.request.status.200"]
    assert_equal 1, counters["rack.request.status.2xx"]

    get '/status/204'
    assert_equal 2, counters["rack.request.total"]
    assert_equal 1, counters["rack.request.status.200"], 'should not increment'
    assert_equal 1, counters["rack.request.status.204"], 'should increment'
    assert_equal 2, counters["rack.request.status.2xx"]
  end

  def test_request_times
    get '/'

    # common for all paths
    assert_equal 1, aggregate["rack.request.time"][:count],
      'should track total request time'

    # should calculte p95 value
    refute_equal aggregate.fetch("rack.request.time", percentile: 95), 0.0

    # status specific
    assert_equal 1, aggregate["rack.request.status.200.time"][:count]
    assert_equal 1, aggregate["rack.request.status.2xx.time"][:count]
  end

  def test_track_http_method_info
    get '/'

    assert_equal 1, counters['rack.request.method.get']
    assert_equal 1, aggregate['rack.request.method.get.time'][:count]

    post '/'

    assert_equal 1, counters['rack.request.method.post']
    assert_equal 1, aggregate['rack.request.method.post.time'][:count]
  end

  def test_track_exceptions
    begin
      get '/exception'
    rescue RuntimeError => e
      raise unless e.message == 'exception raised!'
    end
    assert_equal 1, counters["rack.request.exceptions"]
  end

  def test_track_slow_requests
    get '/slow'
    assert_equal 1, counters["rack.request.slow"]
  end

  private

  def aggregate
    Librato.tracker.collector.aggregate
  end

  def counters
    Librato.tracker.collector.counters
  end

end
