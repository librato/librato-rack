require 'test_helper'
require 'rack/test'

# Tests for universal tracking for all request paths
#
class RequestTest < Minitest::Test
  include Rack::Test::Methods
  include EnvironmentHelpers

  def app
    Rack::Builder.parse_file('test/apps/basic.ru').first
  end

  def setup
    ENV["LIBRATO_TAGS"] = "hostname=metrics-web-stg-1"
    @tags = { hostname: "metrics-web-stg-1" }
  end

  def teardown
    # clear metrics before each run
    aggregate.delete_all
    counters.delete_all
    clear_config_env_vars
  end

  def test_increment_total_and_status
    get '/'
    assert last_response.ok?
    assert_equal 1, counters["rack.request.total"]
    assert_equal 1, counters.fetch("rack.request.status", tags: { status: 200, status_message: "OK" })

    get '/status/204'
    assert_equal 2, counters["rack.request.total"]
    assert_equal 1, counters.fetch("rack.request.status", tags: { status: 200, status_message: "OK" }),         "should not increment"
    assert_equal 1, counters.fetch("rack.request.status", tags: { status: 204, status_message: "No Content" }), "should increment"
  end

  def test_request_times
    get '/'

    # common for all paths
    assert_equal 1, aggregate["rack.request.time"][:count],
      'should track total request time'

    # should calculate p95 value
    assert aggregate.fetch("rack.request.time", tags: @tags, percentile: 95) > 0.0

    # status specific
    assert_equal 1, aggregate.fetch("rack.request.status.time", tags: { status: 200, status_message: "OK" })[:count]
  end

  def test_track_http_method_info
    get '/'

    assert_equal 1, counters.fetch("rack.request.method", tags: { method: "GET" })
    assert_equal 1, aggregate.fetch("rack.request.method.time", tags: { method: "get" })[:count]

    post '/'

    assert_equal 1, counters.fetch("rack.request.method", tags: { method: "POST" })
    assert_equal 1, aggregate.fetch("rack.request.method.time", tags: { method: "post" })[:count]
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
