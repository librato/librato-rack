require 'test_helper'

module Librato
  class CollectorTest < MiniTest::Unit::TestCase
    
    def test_proxy_object_access
      collector = Collector.new
      assert collector.aggregate, 'should have aggregate object'
      assert collector.counters, 'should have counter object'
    end
    
    def test_basic_grouping
      collector = Collector.new
      collector.group 'foo' do |g|
        g.increment :bar
        g.measure :baz, 23
      end
      assert_equal 1, collector.counters['foo.bar']
      assert_equal 23, collector.aggregate['foo.baz'][:sum]
    end
    
  end
end