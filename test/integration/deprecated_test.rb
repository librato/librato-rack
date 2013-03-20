require 'test_helper'
require 'rack/test'

# Tests for deprecated functionality
#
class DeprecatedTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('test/apps/deprecated.ru').first
  end

  def teardown
    # clear metrics before each run
    aggregate.delete_all
    counters.delete_all
  end

  def test_deprecated_config_form
    get '/'
    assert_equal 'deprecated', Librato.tracker.config.prefix
    assert_equal 1, aggregate['deprecated.rack.request.time'][:count]
  end

  private

  def aggregate
    Librato.tracker.collector.aggregate
  end

  def counters
    Librato.tracker.collector.counters
  end

end
