require 'test_helper'

module Librato
  class CollectorTest < Minitest::Test

    def test_proxy_object_access
      collector = Collector.new
      assert collector.aggregate, 'should have aggregate object'
      assert collector.counters, 'should have counter object'
    end

    def test_basic_grouping
      collector = Collector.new
      tags = { region: "us-east-1" }
      collector.group 'foo' do |g|
        g.increment :bar
        g.measure :baz, 23, tags: tags
      end
      assert_equal 1, collector.counters["foo.bar"][:value]
      assert_equal 23, collector.aggregate.fetch("foo.baz", tags: tags)[:sum]
    end

  end
end
