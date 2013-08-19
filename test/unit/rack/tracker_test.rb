require 'test_helper'

module Librato
  class Rack
    class TrackerTest < Minitest::Test

      def test_sets_prefix
        config = Configuration.new
        config.prefix = 'first'

        tracker = Tracker.new(config)
        assert_equal 'first', tracker.collector.prefix

        config.prefix = 'second'
        assert_equal 'second', tracker.collector.prefix
      end

      def test_requires_explicit_source_on_heroku
        config = Configuration.new
        config.user, config.token = 'foo', 'bar'
        @buffer = StringIO.new
        config.log_target = @buffer
        tracker = Tracker.new(config)
        tracker.on_heroku = true

        assert_equal false, tracker.send(:should_start?),
          'should not start with implicit source on heroku'
        assert buffer_lines[0].index('source must be provided')

        config.source = 'myapp'
        new_tracker = Tracker.new(config)
        assert_equal true, new_tracker.send(:should_start?)
      end

      def test_autorun_can_prevent_startup
        ENV['LIBRATO_AUTORUN']='0'
        config = Configuration.new
        config.user, config.token = 'foo', 'bar'
        @buffer = StringIO.new
        config.log_target = @buffer
        tracker = Tracker.new(config)

        assert_equal false, tracker.send(:should_start?),
          'should not start if autorun set to 0'

        ENV.delete('LIBRATO_AUTORUN')
      end

      private

      def buffer_lines
        @buffer.rewind
        @buffer.readlines
      end

    end
  end
end