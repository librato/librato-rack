# # encoding: UTF-8
require 'test_helper'
require 'rack/test'

# Tests for universal tracking for all request paths
#
class TrackerRemoteTest < MiniTest::Unit::TestCase

  # These tests connect to the Metrics server with an account and verify remote
  # functions. They will only run if the below environment variables are set.
  #
  # BE CAREFUL, running these tests will DELETE ALL metrics currently in the
  # test account.
  #
  if ENV['LIBRATO_RACK_TEST_EMAIL'] && ENV['LIBRATO_RACK_TEST_API_KEY']

    def setup
      config = Librato::Rack::Configuration.new
      config.user = ENV['LIBRATO_RACK_TEST_EMAIL']
      config.token = ENV['LIBRATO_RACK_TEST_API_KEY']
      if ENV['LIBRATO_RACK_TEST_API_ENDPOINT']
        config.api_endpoint = ENV['LIBRATO_RACK_TEST_API_ENDPOINT']
      end
      @tracker = Librato::Rack::Tracker.new(config)
      delete_all_metrics
    end

    def test_flush_counters
      tracker.increment :foo                              # simple
      tracker.increment :bar, 2                           # specified
      tracker.increment :foo                              # multincrement
      tracker.increment :foo, :source => 'baz', :by => 3  # custom source
      tracker.flush

      metric_names = client.list.map { |m| m['name'] }
      assert metric_names.include?('foo'), 'foo should be present'
      assert metric_names.include?('bar'), 'bar should be present'

      foo = client.fetch 'foo', :count => 10
      assert_equal 1, foo[source].length
      assert_equal 2, foo[source][0]['value']

      # custom source
      assert_equal 1, foo['baz'].length
      assert_equal 3, foo['baz'][0]['value']

      bar = client.fetch 'bar', :count => 10
      assert_equal 1, bar[source].length
      assert_equal 2, bar[source][0]['value']
    end

    def test_counter_persistent_through_flush
      tracker.increment 'knightrider'
      tracker.increment 'badguys', :sporadic => true
      assert_equal 1, collector.counters['knightrider']
      assert_equal 1, collector.counters['badguys']

      tracker.flush
      assert_equal 0, collector.counters['knightrider']
      assert_equal nil, collector.counters['badguys']
    end

    def test_flush_should_send_measures_and_timings
      tracker.timing  'request.time.total', 122.1
      tracker.measure 'items_bought', 20
      tracker.timing  'request.time.total', 81.3
      tracker.timing  'jobs.queued', 5, :source => 'worker.3'
      tracker.flush

      metric_names = client.list.map { |m| m['name'] }
      assert metric_names.include?('request.time.total'), 'request.time.total should be present'
      assert metric_names.include?('items_bought'), 'request.time.db should be present'

      total = client.fetch 'request.time.total', :count => 10
      assert_equal 2, total[source][0]['count']
      assert_in_delta 203.4, total[source][0]['sum'], 0.1

      items = client.fetch 'items_bought', :count => 10
      assert_equal 1, items[source][0]['count']
      assert_in_delta 20, items[source][0]['sum'], 0.1

      jobs = client.fetch 'jobs.queued', :count => 10
      assert_equal 1, jobs['worker.3'][0]['count']
      assert_in_delta 5, jobs['worker.3'][0]['sum'], 0.1
    end

    def test_flush_should_purge_measures_and_timings
      tracker.timing  'request.time.total', 122.1
      tracker.measure 'items_bought', 20
      tracker.flush

      assert collector.aggregate.empty?, 'measures and timings should be cleared with flush'
    end

    def test_empty_flush_should_not_be_sent
      tracker.flush
      assert_equal [], client.list
    end

    def test_flush_respects_prefix
      config.prefix = 'testyprefix'

      tracker.timing 'mytime', 221.1
      tracker.increment 'mycount', 4
      tracker.flush

      metric_names = client.list.map { |m| m['name'] }
      assert metric_names.include?('testyprefix.mytime'), 'testyprefix.mytime should be present'
      assert metric_names.include?('testyprefix.mycount'), 'testyprefix.mycount should be present'

      mytime = client.fetch 'testyprefix.mytime', :count => 10
      assert_equal 1, mytime[source][0]['count']

      mycount = client.fetch 'testyprefix.mycount', :count => 10
      assert_equal 4, mycount[source][0]['value']
    end

    def test_flush_recovers_from_failure
      # create a metric foo of counter type
      client.submit :foo => {:type => :counter, :value => 12}

      # failing flush - submit a foo measurement as a gauge (type mismatch)
      tracker.measure :foo, 2.12
      tracker.flush

      foo = client.fetch :foo, :count => 10
      assert_equal 1, foo['unassigned'].length
      assert_nil foo[source] # shouldn't have been accepted

      tracker.measure :boo, 2.12
      tracker.flush

      boo = client.fetch :boo, :count => 10
      assert_equal 2.12, boo[source][0]["value"]
    end

    def test_flush_handles_invalid_metric_names
      tracker.increment :foo              # valid
      tracker.increment 'fübar'           # invalid
      tracker.measure 'fu/bar/baz', 12.1  # invalid
      tracker.flush

      metric_names = client.list.map { |m| m['name'] }
      assert metric_names.include?('foo')

      # should have saved values for foo
      foo = client.fetch :foo, :count => 5
      assert_equal 1.0, foo[source][0]["value"]
    end

    def test_flush_handles_invalid_sources_names
      tracker.increment :foo, :source => 'atreides'         # valid
      tracker.increment :bar, :source => 'glébnöst'         # invalid
      tracker.measure 'baz', 2.25, :source => 'b/l/ak/nok'  # invalid
      tracker.flush

      # should have saved values for foo
      foo = client.fetch :foo, :count => 5
      assert_equal 1.0, foo['atreides'][0]["value"]
    end

    private

    def tracker
      @tracker
    end

    def client
      @tracker.send(:client)
    end

    def collector
      @tracker.collector
    end

    def config
      @tracker.config
    end

    def source
      @tracker.qualified_source
    end

    def delete_all_metrics
      metric_names = client.list.map { |metric| metric['name'] }
      client.delete(*metric_names) if !metric_names.empty?
    end

  else
    # ENV vars not set
    puts "Skipping remote tests..."
  end

end
