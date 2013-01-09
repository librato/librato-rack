require 'test_helper'

module Librato::Rack
  class ConfigurationTest < MiniTest::Unit::TestCase
  
    def teardown
      ENV.delete('LIBRATO_USER')
      ENV.delete('LIBRATO_TOKEN')
      ENV.delete('LIBRATO_SOURCE')
      # legacy
      ENV.delete('LIBRATO_METRICS_USER')
      ENV.delete('LIBRATO_METRICS_TOKEN')
      ENV.delete('LIBRATO_METRICS_SOURCE')
    end
  
    def test_defaults
      config = Configuration.new
      assert_equal 60, config.flush_interval
      assert_equal Librato::Metrics.api_endpoint, config.api_endpoint
    end
    
    def test_environmental_variable_config
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
  
  end
end