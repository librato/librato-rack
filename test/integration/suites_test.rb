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
    assert_equal 1, counters['rack.request']
    assert_equal 1, aggregate["rack.request.time"][:count]

    # rack.request.method metrics (rack_method suite) should not get logged
    assert_equal nil, counters.fetch('rack.request.method', tags: { method: 'GET' })
    assert_equal nil, aggregate.fetch('rack.request.method.time', tags: { method: 'get' })

    # rack.request.status metrics (rack_status suite) should not get logged
    assert_equal nil, counters.fetch('rack.request.status', tags: { status: 200, status_message: 'OK' })
    assert_equal nil, counters.fetch('rack.request.status.time', tags: { status: 200, status_message: 'OK' })
  end

  private

  def aggregate
    Librato.tracker.collector.aggregate
  end

  def counters
    Librato.tracker.collector.counters
  end

end
