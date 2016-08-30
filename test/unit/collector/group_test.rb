require 'test_helper'

module Librato
  class Collector
    class GroupTest < Minitest::Test

      def setup
        @tags = { region: "us-east-1" }
      end

      def test_increment
        collector = Collector.new
        collector.group 'foo' do |g|
          g.increment :bar
          g.increment :baz, :source => 'bang'
        end
        assert_equal 1, collector.counters['foo.bar']
        assert_equal 1, collector.counters.fetch('foo.baz', source: 'bang')
      end

      def test_measure
        collector = Collector.new
        collector.group 'foo' do |g|
          g.measure :baz, 23, tags: @tags
        end
        assert_equal 23, collector.aggregate.fetch("foo.baz", tags: @tags)[:sum]
      end

      def test_timing
        collector = Collector.new
        collector.group 'foo' do |g|
          g.timing :bam, 32.0, tags: @tags
        end
        assert_equal 32.0, collector.aggregate.fetch("foo.bam", tags: @tags)[:sum]
      end

      def test_timing_block
        collector = Collector.new
        collector.group 'foo' do |g|
          g.timing :bak, tags: @tags do
            sleep 0.01
          end
        end
        assert_in_delta 10.0, collector.aggregate.fetch("foo.bak", tags: @tags)[:sum], 2
      end

      def test_nesting
        collector = Collector.new
        collector.group 'foo' do |g|
          g.group :bar do |b|
            b.increment :baz, 2
          end
        end
        assert_equal 2, collector.counters['foo.bar.baz']
      end

    end
  end
end
