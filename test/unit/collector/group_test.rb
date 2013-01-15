require 'test_helper'

module Librato
  class Collector
    class GroupTest < MiniTest::Unit::TestCase

      def test_increment
        collector = Collector.new
        collector.group 'foo' do |g|
          g.increment :bar
        end
        assert_equal 1, collector.counters['foo.bar']
      end

      def test_measure
        collector = Collector.new
        collector.group 'foo' do |g|
          g.measure :baz, 23
        end
        assert_equal 23, collector.aggregate['foo.baz'][:sum]
      end

      def test_timing
        collector = Collector.new
        collector.group 'foo' do |g|
          g.timing :bam, 32.0
        end
        assert_equal 32.0, collector.aggregate['foo.bam'][:sum]
      end

      def test_timing_block
        collector = Collector.new
        collector.group 'foo' do |g|
          g.timing :bak do
            sleep 0.01
          end
        end
        assert_in_delta 10.0, collector.aggregate['foo.bak'][:sum], 2
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