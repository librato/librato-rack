require 'test_helper'
require 'rack/test'

# Tests for universal tracking for all request paths
#
class RequestTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('test/apps/basic.ru').first
  end

  def test_increment_total_and_status
    get '/'
    assert last_response.ok?
    assert_equal 1, counters["rack.request.total"]
    assert_equal 1, counters["rack.request.status.200"]
    assert_equal 1, counters["rack.request.status.2xx"]

    get '/status/204'
    assert_equal 2, counters["rack.request.total"]
    assert_equal 1, counters["rack.request.status.200"]
    assert_equal 1, counters["rack.request.status.204"]
    assert_equal 2, counters["rack.request.status.2xx"]
  end

  private

  def counters
    Librato.collector.counters
  end

  # def test_increment_status

  # end
  #
  #   test 'request times' do
  #     visit root_path
  #
  #     # common for all paths
  #     assert_equal 1, aggregate["rails.request.time"][:count], 'should record total time'
  #     assert_equal 1, aggregate["rails.request.time.db"][:count], 'should record db time'
  #     assert_equal 1, aggregate["rails.request.time.view"][:count], 'should record view time'
  #
  #     # status specific
  #     assert_equal 1, aggregate["rails.request.status.200.time"][:count]
  #     assert_equal 1, aggregate["rails.request.status.2xx.time"][:count]
  #   end
  #
  #   test 'track exceptions' do
  #     begin
  #       visit exception_path #rescue nil
  #     rescue RuntimeError => e
  #       raise unless e.message == 'test exception!'
  #     end
  #     assert_equal 1, counters["rails.request.exceptions"]
  #   end
  #
  #   test 'track slow requests' do
  #     visit slow_path
  #     assert_equal 1, counters["rails.request.slow"]
  #   end

end
