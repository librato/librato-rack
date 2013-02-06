require 'test_helper'

module Librato
  class Rack
    class ConfigurationTest < MiniTest::Unit::TestCase

      def setup
        clear_env_vars
      end

      def teardown
        clear_env_vars
      end

      def test_defaults
        config = Configuration.new
        assert_equal 60, config.flush_interval
        assert_equal Librato::Metrics.api_endpoint, config.api_endpoint
      end

      def test_environment_variable_config
        ENV['LIBRATO_USER'] = 'foo@bar.com'
        ENV['LIBRATO_TOKEN'] = 'api_key'
        ENV['LIBRATO_SOURCE'] = 'source'
        config = Configuration.new
        assert_equal 'foo@bar.com', config.user
        assert_equal 'api_key', config.token
        assert_equal 'source', config.source
        #assert Librato::Rails.explicit_source, 'source is explicit'
      end

      def test_legacy_env_variable_config
        ENV['LIBRATO_METRICS_USER'] = 'foo@bar.com'
        ENV['LIBRATO_METRICS_TOKEN'] = 'api_key'
        ENV['LIBRATO_METRICS_SOURCE'] = 'source'
        config = Configuration.new
        assert_equal 'foo@bar.com', config.user
        assert_equal 'api_key', config.token
        assert_equal 'source', config.source
        # assert Librato::Rails.explicit_source, 'source is explicit'
      end

      def test_explicit_source
        config = Configuration.new
        assert !config.explicit_source?
        config.source = 'tessaract'
        assert config.explicit_source?
        config.source = nil
        assert !config.explicit_source?, 'source should no long be explicit when reset'
      end

      def test_prefix_change_notification
        config = Configuration.new
        listener = listener_object
        config.register_listener(listener)
        config.prefix = 'newfoo'
        assert_equal 'newfoo', listener.prefix
      end

      private

      def clear_env_vars
        ENV.delete('LIBRATO_USER')
        ENV.delete('LIBRATO_TOKEN')
        ENV.delete('LIBRATO_SOURCE')
        ENV.delete('LIBRATO_LOG_LEVEL')
        # legacy
        ENV.delete('LIBRATO_METRICS_USER')
        ENV.delete('LIBRATO_METRICS_TOKEN')
        ENV.delete('LIBRATO_METRICS_SOURCE')
      end

      def listener_object
        listener = Object.new
        def listener.prefix=(prefix)
          @prefix = prefix
        end
        def listener.prefix
          @prefix
        end
        listener
      end

    end
  end
end