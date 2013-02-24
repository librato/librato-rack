require 'test_helper'
require 'stringio'

module Librato
  class Rack
    class LoggerTest < MiniTest::Unit::TestCase

      def setup
        @buffer = StringIO.new
        #log_object = ::Logger.new(@buffer) # stdlib logger
        @logger = Logger.new(@buffer) # rack logger
      end

      def test_log_levels
        assert_equal :info, @logger.log_level, 'should default to info'

        @logger.log_level = :debug
        assert_equal :debug, @logger.log_level, 'should accept symbols'

        @logger.log_level = 'trace'
        assert_equal :trace, @logger.log_level, 'should accept strings'

        assert_raises(InvalidLogLevel) { @logger.log_level = :foo }
      end

      def test_simple_logging
        @logger.log_level = :info

        # logging at log level
        @logger.log :info, 'a log message'
        assert_equal 1, buffer_lines.length, 'should have added a line'
        assert buffer_lines[0].index('a log message'), 'should log message'

        # logging above level
        @logger.log :error, 'an error message'
        assert_equal 2, buffer_lines.length, 'should have added a line'
        assert buffer_lines[1].index('an error message'), 'should log message'

        # logging below level
        @logger.log :debug, 'a debug message'
        assert_equal 2, buffer_lines.length, 'should not have added a line'
      end

      def test_logging_through_stdlib_logger_object
        stdlib_logger = ::Logger.new(@buffer)
        @logger = Logger.new(stdlib_logger)

        @logger.log_level = :info

        # logging at log level
        @logger.log :info, 'a log message'
        assert_equal 1, buffer_lines.length, 'should have added a line'
        assert buffer_lines[0].index('a log message'), 'should log message'

        # logging above level
        @logger.log :error, 'an error message'
        assert_equal 2, buffer_lines.length, 'should have added a line'
        assert buffer_lines[1].index('an error message'), 'should log message'

        # logging below level
        @logger.log :debug, 'a debug message'
        assert_equal 2, buffer_lines.length, 'should not have added a line'
      end

      def test_block_logging
        @logger.log_level = :info

        # logging at log level
        @logger.log(:info) { "log statement" }
        assert_equal 1, buffer_lines.length, 'should have added a line'
        assert buffer_lines[0].index('log statement'), 'should log message'
      end

      def test_log_prefix
        assert_equal '[librato-rack] ', @logger.prefix

        @logger.prefix = '[test prefix] '
        @logger.log :error, 'an error message'
        assert buffer_lines[0].index('[test prefix] '), 'should use prefix'
      end

      private

      def buffer_lines
        @buffer.rewind
        @buffer.readlines
      end

    end
  end
end