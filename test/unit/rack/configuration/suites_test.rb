require 'test_helper'

module Librato
  class Rack
    class SuitesTest < Minitest::Test
      include EnvironmentHelpers

      def setup;    clear_config_env_vars; end
      def teardown; clear_config_env_vars; end

      def test_suites_defaults
        config = Configuration.new
        assert config.metric_suites.include?(:rack), "should include 'rack' by default"
        refute config.metric_suites.include?(:foo), "should not include 'foo' by default"
      end

      def test_suites_configured_by_explicit_list
        ENV['LIBRATO_SUITES'] = 'abc, jkl,prq , xyz'
        config = Configuration.new
        [:abc, :jkl, :prq, :xyz].each do |suite|
          assert config.metric_suites.include?(suite), "expected '#{suite}' to be active"
        end
        refute config.metric_suites.include?(:rack), "should not include 'rack' by default"
        refute config.metric_suites.include?(:something_else), 'should not include unspecified'
      end

      def test_suites_configured_by_inclusion
        ENV['LIBRATO_SUITES'] = '+abc, jkl,prq , xyz'
        config = Configuration.new

        [:rack_method, :jkl, :prq, :xyz].each do |suite|
          assert config.metric_suites.include?(suite), "expected '#{suite.to_s}' to be active"
        end
        assert config.metric_suites.include?(:rack), "should include 'rack' by default"
      end

      def test_suites_configured_by_exclusion
        ENV['LIBRATO_SUITES'] = '-rack_method, jkl,prq , xyz'
        config = Configuration.new

        [:rack_method, :jkl, :prq, :xyz].each do |suite|
          refute config.metric_suites.include?(suite), "expected '#{suite.to_s}' to be inactive"
        end
        assert config.metric_suites.include?(:rack), "should include 'rack' by default"
      end

      def test_suites_all
        ENV['LIBRATO_SUITES'] = 'all'
        config = Configuration.new

        [:foo, :bar, :baz].each do |suite|
          assert config.metric_suites.include?(suite), "expected '#{suite}' to be active"
        end
      end

      def test_suites_none
        ENV['LIBRATO_SUITES'] = 'NONE'
        config = Configuration.new

        [:foo, :bar, :baz].each do |suite|
          refute config.metric_suites.include?(suite), "expected '#{suite.to_s}' to be active"
        end
      end

    end
  end
end
