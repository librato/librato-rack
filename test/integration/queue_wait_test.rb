require 'test_helper'
require 'rack/test'

# Tests for universal tracking for all request paths
#
class QueueWaitTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('test/apps/queue_wait.ru').first
  end

  def teardown
    # clear metrics before each run
    aggregate.delete_all
    counters.delete_all
  end

  def test_milliseconds
    get '/milli'

    # puts "milli: #{aggregate["rack.request.queue.time"].inspect}"
    assert_equal 1, aggregate["rack.request.queue.time"][:count],
      'should track total queue time'
    assert_in_delta 5, aggregate["rack.request.queue.time"][:sum], 4
  end

  def test_microseconds
    get '/micro'

    # puts "micro: #{aggregate["rack.request.queue.time"].inspect}"
    assert_equal 1, aggregate["rack.request.queue.time"][:count],
      'should track total queue time'
    assert_in_delta 10, aggregate["rack.request.queue.time"][:sum], 4
  end

  def test_queue_start
    get '/queue_start'

    # puts "micro: #{aggregate["rack.request.queue.time"].inspect}"
    assert_equal 1, aggregate["rack.request.queue.time"][:count],
      'should track total queue time'
    assert_in_delta 15, aggregate["rack.request.queue.time"][:sum], 6
  end

  def test_with_t
    get '/with_t'

    # puts "micro: #{aggregate["rack.request.queue.time"].inspect}"
    assert_equal 1, aggregate["rack.request.queue.time"][:count],
      'should track total queue time'
    assert_in_delta 20, aggregate["rack.request.queue.time"][:sum], 6
  end

  def test_with_period
    get '/with_period'

    # give jruby a bit more time since it can be slow
    delta = defined?(JRUBY_VERSION) ? 10 : 6
    assert_equal 1, aggregate["rack.request.queue.time"][:count],
      'should track total queue time'
    assert_in_delta 25, aggregate["rack.request.queue.time"][:sum], delta
  end

  private

  def aggregate
    Librato.tracker.collector.aggregate
  end

  def counters
    Librato.tracker.collector.counters
  end

end
