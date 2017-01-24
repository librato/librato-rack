require 'test_helper'

module Librato
  class Collector
    class CounterCacheTest < Minitest::Test

      def test_basic_operations
        cc = CounterCache.new(default_tags: { host: 'metricsweb-stagevpc-1' })
        cc.increment :foo
        assert_equal 1, cc[:foo][:value]

        # accepts optional argument
        cc.increment :foo, :by => 5
        assert_equal 6, cc[:foo][:value]

        # legacy style
        cc.increment :foo, 2
        assert_equal 8, cc[:foo][:value]

        # strings or symbols work
        cc.increment 'foo'
        assert_equal 9, cc['foo'][:value]
      end

      def test_custom_tags
        cc = CounterCache.new

        cc.increment :foo, tags: { hostname: "bar" }
        assert_equal 1, cc.fetch(:foo, tags: { hostname: "bar" })[:value]

        # symbols also work
        cc.increment :foo, tags: { hostname: :baz }
        assert_equal 1, cc.fetch(:foo, tags: { hostname: :baz })[:value]

        # strings and symbols are interchangable
        cc.increment :foo, tags: { hostname: :bar }
        assert_equal 2, cc.fetch(:foo, tags: { hostname: "bar" })[:value]

        # custom source and custom increment
        cc.increment :foo, tags: { hostname: "boombah" }, by: 10
        assert_equal 10, cc.fetch(:foo, tags: { hostname: "boombah" })[:value]
      end

      def test_legacy_source
        cc = CounterCache.new

        cc.increment :foo, source: "bar"

        assert_equal 1, cc.fetch(:foo, tags: { source: "bar" })[:value]
      end

      def test_sporadic
        cc = CounterCache.new(default_tags: { host: 'metricsweb-stagevpc-1' })

        cc.increment :foo
        cc.increment :foo, tags: { hostname: "bar" }

        cc.increment :baz, :sporadic => true
        cc.increment :baz, tags: { hostname: 118 }, sporadic: true
        assert_equal 1, cc[:baz][:value]
        assert_equal 1, cc.fetch(:baz, tags: { hostname: 118 })[:value]

        # persist values once
        cc.flush_to(Librato::Metrics::Queue.new)

        # normal values persist
        assert_equal 0, cc[:foo][:value]
        assert_equal 0, cc.fetch(:foo, tags: { hostname: "bar" })[:value]

        # sporadic do not
        assert_equal nil, cc[:baz]
        assert_equal nil, cc.fetch(:baz, tags: { hostname: 118 })

        # add a different sporadic metric
        cc.increment :bazoom, :sporadic => true
        assert_equal 1, cc[:bazoom][:value]

        # persist values again
        cc.flush_to(Librato::Metrics::Queue.new)
        assert_equal nil, cc[:bazoom]
      end

      def test_flushing
        cc = CounterCache.new
        tags = { hostname: "foobar" }

        cc.increment :foo
        cc.increment :bar, :by => 2
        cc.increment :foo, tags: tags
        cc.increment :foo, tags: tags, by: 3

        q = Librato::Metrics::Queue.new(tags: { region: "us-east-1" })
        cc.flush_to(q)

        expected = Set.new [{:name=>"foo", :value=>1},
                    {:name=>"foo", :value=>4, :tags=>tags},
                    {:name=>"bar", :value=>2}]
        queued = Set.new(q.measurements)
        queued.each { |hash| hash.delete(:time) }
        assert_equal queued, expected
      end

      def test_default_tags
        default_tags = { host: 'metricsweb-stagevpc-1' }
        cc = CounterCache.new(default_tags: default_tags)
        cc.increment 'user.signup'

        assert_equal 1, cc.fetch('user.signup')[:value]
        assert_equal default_tags, cc.fetch('user.signup')[:tags]
      end

      def test_tags_option
        default_tags = { host: 'metricsweb-stagevpc-1' }
        tags_option = { plan: 'developer' }
        cc = CounterCache.new(default_tags: default_tags)
        cc.increment 'user.signup', tags: tags_option

        assert_equal 1, cc.fetch('user.signup', tags: tags_option)[:value]
        assert_equal tags_option, cc.fetch('user.signup', tags: tags_option)[:tags]
      end

      def test_inherit_tags
        default_tags = { host: 'metricsweb-stagevpc-1' }
        tags_option = { plan: 'developer' }
        merged_tags = default_tags.merge(tags_option)
        cc = CounterCache.new(default_tags: default_tags)
        cc.increment 'user.signup', tags: tags_option, inherit_tags: true

        assert_equal 1, cc.fetch('user.signup', tags: merged_tags)[:value]
        assert_equal merged_tags, cc.fetch('user.signup', tags: merged_tags)[:tags]
      end

    end
  end
end
