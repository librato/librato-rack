require 'test_helper'

module Librato
  class Rack
    class TrackerTest < MiniTest::Unit::TestCase

      def test_sets_prefix
        config = Configuration.new
        config.prefix = 'first'

        tracker = Tracker.new(config)
        assert_equal 'first', tracker.collector.prefix

        config.prefix = 'second'
        assert_equal 'second', tracker.collector.prefix
      end

    end
  end
end