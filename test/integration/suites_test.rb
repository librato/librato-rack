require 'test_helper'
require 'rack/test'

# Tests to ensure config suites work
#
class SuitesTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('test/apps/custom_suites.ru').first
  end

  def teardown
    # clear metrics before each run
    aggregate.delete_all
    counters.delete_all
  end

  def test_no_rack_status
    get '/'
    assert last_response.ok?

    # rack.request metrics (rack suite) should get logged
    assert_equal 1, counters["rack.request.total"]
    assert_equal 1, aggregate["rack.request.time"][:count]

    # rack.request.method metrics (rack_method suite) should not get logged
    assert_nil counters['rack.request.method.get']
    assert_nil aggregate['rack.request.method.get.time']

    # rack.request.status metrics (rack_status suite) should not get logged
    assert_nil counters["rack.request.status.200"]
    assert_nil counters["rack.request.status.2xx"]
    assert_nil counters["rack.request.status.200.time"]
    assert_nil counters["rack.request.status.2xx.time"]
  end

  private

  def aggregate
    Librato.tracker.collector.aggregate
  end

  def counters
    Librato.tracker.collector.counters
  end

end
