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

      def test_requires_tags_on_heroku
        config = Configuration.new
        config.user, config.token = 'foo', 'bar'
        @buffer = StringIO.new
        config.log_target = @buffer
        tracker = Tracker.new(config)
        tracker.on_heroku = true

        assert_equal false, tracker.send(:should_start?),
          'should not start with implicit tags on heroku'
        assert buffer_lines[0].index("tags must be provided")

        config.tags = { hostname: "myapp" }
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

      def test_invalid_tags_can_prevent_startup
        config = Configuration.new
        config.user, config.token = "foo", "bar"
        @buffer = StringIO.new
        config.log_target = @buffer
        config.tags = { hostname: "!!!" }
        tracker_1 = Tracker.new(config)

        assert_equal false, tracker_1.send(:should_start?)
        assert buffer_lines.to_s.include?("invalid tags")

        config.tags = { "!!!" => "metrics-web-stg-1" }
        tracker_2 = Tracker.new(config)

        assert_equal false, tracker_2.send(:should_start?)
        assert buffer_lines.to_s.include?("invalid tags")
      end

      def test_suite_configured
        ENV['LIBRATO_SUITES'] = 'abc,prq'

        tracker = Tracker.new(Configuration.new)
        assert tracker.suite_enabled?(:abc)
        assert tracker.suite_enabled?(:prq)
        refute tracker.suite_enabled?(:xyz)
      ensure
        ENV.delete('LIBRATO_SUITES')
      end

      private

      def buffer_lines
        @buffer.rewind
        @buffer.readlines
      end

    end
  end
end
