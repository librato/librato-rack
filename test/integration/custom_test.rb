require 'test_helper'
require 'rack/test'

# Tests for universal tracking for all request paths
#
class CustomTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('test/apps/custom.ru').first
  end

  def teardown
    # clear metrics before each run
    aggregate.delete_all
    counters.delete_all
  end

  def test_increment
    get '/increment'
    assert_equal 1, counters[:hits]
    2.times { get '/increment' }
    assert_equal 3, counters[:hits]
  end

  def test_measure
    get '/measure'
    assert_equal 3.0, aggregate[:nodes][:sum]
    assert_equal 1, aggregate[:nodes][:count]
  end

  def test_timing
    get '/timing'
    assert_equal 1, aggregate['lookup.time'][:count]
  end

  def test_timing_block
    get '/timing_block'
    assert_equal 1, aggregate['sleeper'][:count]
    assert_in_delta 10, aggregate['sleeper'][:sum], 10
  end

  def test_grouping
    get '/group'
    assert_equal 1, counters['did.a.thing']
    assert_equal 1, aggregate['did.a.timing'][:count]
  end

  private

  def aggregate
    Librato.collector.aggregate
  end

  def counters
    Librato.collector.counters
  end

end
