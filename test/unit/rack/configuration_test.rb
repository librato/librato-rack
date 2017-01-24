require 'test_helper'

module Librato
  class Rack
    class ConfigurationTest < Minitest::Test
      include EnvironmentHelpers

      def setup;    clear_config_env_vars; end
      def teardown; clear_config_env_vars; end

      def test_defaults
        config = Configuration.new
        assert_equal 60, config.flush_interval
        assert_equal Librato::Metrics.api_endpoint, config.api_endpoint
        assert_equal '', config.suites
        assert_equal Hash.new, config.tags
      end

      def test_environment_variable_config
        ENV['LIBRATO_USER'] = 'foo@bar.com'
        ENV['LIBRATO_TOKEN'] = 'api_key'
        ENV["LIBRATO_TAGS"] = "hostname=metrics-web-stg-1"
        ENV['LIBRATO_PROXY'] = 'http://localhost:8080'
        ENV['LIBRATO_SUITES'] = 'foo,bar'
        expected_tags = { hostname: "metrics-web-stg-1" }
        config = Configuration.new
        assert_equal 'foo@bar.com', config.user
        assert_equal 'api_key', config.token
        assert_equal expected_tags, config.tags
        assert_equal 'http://localhost:8080', config.proxy
        assert_equal 'foo,bar', config.suites
        #assert Librato::Rails.explicit_source, 'source is explicit'
      end

      def test_http_proxy_env_variable_config
        ENV['http_proxy'] = 'http://localhost:8888'
        config = Configuration.new
        assert_equal 'http://localhost:8888', config.proxy
      end

      def test_has_tags
        config = Configuration.new
        assert !config.has_tags?
        config.tags = { hostname: "tessaract" }
        assert config.has_tags?
        config.tags = nil
        assert !config.has_tags?, "tags are not valid when nil"
        config.tags = {}
        assert !config.has_tags?, "tags are not valid when empty"
      end

      def test_invalid_tags_env_var
        ENV["LIBRATO_TAGS"] = "loljk"
        assert_raises Librato::Rack::InvalidTagConfiguration do
         config = Configuration.new
        end
      end

      def test_prefix_change_notification
        config = Configuration.new
        listener = listener_object
        config.register_listener(listener)
        config.prefix = 'newfoo'
        assert_equal 'newfoo', listener.prefix
      end

      def test_event_mode
        config = Configuration.new
        assert_nil config.event_mode

        config.event_mode = :synchrony
        assert_equal :synchrony, config.event_mode

        # handle string config
        config.event_mode = 'eventmachine'
        assert_equal :eventmachine, config.event_mode

        # handle invalid
        config2 = Configuration.new
        config2.event_mode = 'fooballoo'
        assert_nil config2.event_mode

        # env detection
        ENV['LIBRATO_EVENT_MODE'] = 'eventmachine'
        config3 = Configuration.new
        assert_equal :eventmachine, config3.event_mode
      end

      private

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
