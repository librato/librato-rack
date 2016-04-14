require 'test_helper'
require 'rack/test'

# Tests to ensure tracking is disabled when a suite is removed. These tests
# largely ensure that behavior verified positively other suites doesn't
# happen when specific suites are disabled.
#
class NoSuitesTest < Minitest::Test
  include Rack::Test::Methods
  include EnvironmentHelpers

  def app
    ENV['LIBRATO_SUITES'] = 'none'
    Rack::Builder.parse_file('test/apps/basic.ru').first
  end

  def teardown
    # clear metrics before each run
    aggregate.delete_all
    counters.delete_all
    clear_config_env_vars
  end

  def test_increment_total
    get '/'
    assert last_response.ok?
    assert_nil counters["rack.request.total"], 'should not increment'
  end

  def test_track_queue_time
    get '/'
    assert last_response.ok?
    assert_equal nil, aggregate["rack.request.queue.time"]
  end

  def test_increment_status
    get '/'
    assert last_response.ok?
    assert_nil counters["rack.request.status.200"], 'should not increment'
    assert_nil counters["rack.request.status.2xx"], 'should not increment'
  end

  def test_track_http_method_info
    get '/'
    assert_nil counters['rack.request.method.get']

    post '/'
    assert_nil counters['rack.request.method.post']
  end

  def test_increment_exception
    begin
      get '/exception'
    rescue RuntimeError => e
      raise unless e.message == 'exception raised!'
    end

    assert_nil counters["rack.request.exceptions"], 'should not increment'
  end

  private

  def aggregate
    Librato.tracker.collector.aggregate
  end

  def counters
    Librato.tracker.collector.counters
  end

end
