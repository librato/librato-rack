require 'test_helper'

module Librato
  class Rack
    class ValidatingQueueTest < Minitest::Test
      def setup
        @queue = ValidatingQueue.new
      end

      def test_valid_metric_name_tag_name_tag_value
        @queue.add valid_metric_name: {
          value: rand(100),
          tags: { valid_tag_name: 'valid_tag_value' }
        }
        @queue.validate_measurements
        refute_empty @queue.queued[:measurements]
      end

      def test_valid_tag_value_with_whitespace
        @queue.add valid_metric_name: {
          value: rand(100),
          tags: { valid_tag_name: 'valid tag value' }
        }
        @queue.validate_measurements
        refute_empty @queue.queued[:measurements]
      end

      def test_invalid_metric_name
        @queue.add 'invalid metric name' => {
          value: rand(100),
          tags: { valid_tag_name: 'valid_tag_value' }
        }
        @queue.validate_measurements
        assert_empty @queue.queued[:measurements]
      end

      def test_invalid_tag_name
        @queue.add valid_metric_name: {
          value: rand(100),
          tags: { 'invalid_tag_name!' => 'valid_tag_value' }
        }
        @queue.validate_measurements
        assert_empty @queue.queued[:measurements]
      end

      def test_invalid_tag_value
        @queue.add valid_metric_name: {
          value: rand(100),
          tags: { valid_tag_name: 'invalid_tag_value!' }
        }
        @queue.validate_measurements
        assert_empty @queue.queued[:measurements]
      end
    end
  end
end
