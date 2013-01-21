require 'test_helper'

module Librato
  class Rack
    class LoggerTest < MiniTest::Unit::TestCase

      def setup
        @read_buffer, write = IO.pipe
        log_object = ::Logger.new(write) # stdlib logger
        @logger = Logger.new(log_object) # rack logger
      end

      def test_log_levels
        assert_equal :info, @logger.log_level, 'should default to info'

        @logger.log_level = :debug
        assert_equal :debug, @logger.log_level, 'should accept symbols'

        @logger.log_level = 'trace'
        assert_equal :trace, @logger.log_level, 'should accept strings'

        assert_raises(InvalidLogLevel) { @logger.log_level = :foo }
      end

    end
  end
end