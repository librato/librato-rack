require 'test_helper'

module Librato
  class Collector
    class AggregatorTest < Minitest::Test

      def setup
        @agg = Aggregator.new
      end

      def test_adding_timings
        @agg.timing 'request.time.total', 23.7
        @agg.timing 'request.time.db', 5.3
        @agg.timing 'request.time.total', 64.3

        assert_equal 2, @agg['request.time.total'][:count]
        assert_equal 88.0, @agg['request.time.total'][:sum]
      end

      def test_block_timing
        @agg.timing 'my.task' do
          sleep 0.2
        end
        assert_in_delta @agg['my.task'][:sum], 200, 50

        @agg.timing('another.task') { sleep 0.1 }
        assert_in_delta @agg['another.task'][:sum], 100, 50
      end

      def test_percentiles
        # simple case
        [0.1, 0.2, 0.3].each do |val|
          @agg.timing 'a.sample.thing', val, percentile: 50
        end
        assert_equal 0.2, @agg.fetch('a.sample.thing', percentile: 50),
          'can calculate percentile'

        # multiple percentiles
        [0.2, 0.35].each do |val|
          @agg.timing 'a.sample.thing', val, percentile: [80, 95]
        end
        assert_equal 0.31, @agg.fetch('a.sample.thing', percentile: 65),
          'can calculate another percentile simultaneously'
        assert_equal 0.35, @agg.fetch('a.sample.thing', percentile: 95),
          'can calculate another percentile simultaneously'

        # ensure storage is efficient: this is a little gross because we
        # have to inquire past the public interface, but important to verify
        assert_equal 1, @agg.instance_variable_get('@percentiles').length,
          'maintains all samples for same metric/source in one pool'
      end

      def test_percentiles_invalid
        # less than 0.0
        assert_raises(Librato::Collector::InvalidPercentile) {
          @agg.timing 'a.sample.thing', 123, percentile: -25.5
        }

        # greater than 100.0
        assert_raises(Librato::Collector::InvalidPercentile) {
          @agg.timing 'a.sample.thing', 123, percentile: 100.2
        }
      end

      def test_percentiles_with_source
        Array(1..10).each do |val|
          @agg.timing 'a.sample.thing', val, percentile: 50, source: 'foo'
        end
        assert_equal 5.5,
          @agg.fetch('a.sample.thing', source: 'foo', percentile: 50),
          'can calculate percentile with source'
      end

      # Todo: mult percentiles, block form, with source, invalid percentile

      def test_return_values
        simple = @agg.timing 'simple', 20
        assert_equal nil, simple

        timing = @agg.timing 'foo' do
          sleep 0.1
          'bar'
        end
        assert_equal 'bar', timing
      end

      def test_custom_source
        # sources are kept separate
        @agg.measure 'meaning.of.life', 1
        @agg.measure 'meaning.of.life', 42, :source => 'douglas_adams'
        assert_equal 1.0, @agg.fetch('meaning.of.life')[:sum]
        assert_equal 42.0, @agg.fetch('meaning.of.life', :source => 'douglas_adams')[:sum]

        # sources work with time blocks
        @agg.timing 'mytiming', :source => 'mine' do
          sleep 0.02
        end
        assert_in_delta @agg.fetch('mytiming', :source => 'mine')[:sum], 20, 10
      end

      def test_flush
        @agg.measure 'meaning.of.life', 1
        @agg.measure 'meaning.of.life', 42, :source => 'douglas_adams'

        q = Librato::Metrics::Queue.new
        @agg.flush_to(q)
        expected = Set.new([
          {:name=>"meaning.of.life", :count=>1, :sum=>1.0, :min=>1.0, :max=>1.0},
          {:name=>"meaning.of.life", :count=>1, :sum=>42.0, :min=>42.0, :max=>42.0, :source=>"douglas_adams"}])
        assert_equal expected, Set.new(q.queued[:gauges])
      end

    end
  end
end