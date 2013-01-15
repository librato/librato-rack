require 'test_helper'

module Librato
  class CollectorTest < MiniTest::Unit::TestCase
    
    def test_proxy_object_access
      collector = Collector.new
      assert collector.aggregate, 'should have aggregate object'
      assert collector.counters, 'should have counter object'
    end
    
  end
end