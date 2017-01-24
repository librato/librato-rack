require "json"

module Librato
  class Collector
    # maintains storage of a set of incrementable, counter-like
    # measurements
    #
    class CounterCache
      SEPARATOR = '%%'

      extend Forwardable

      def_delegators :@cache, :empty?

      attr_reader :default_tags

      def initialize(options={})
        @cache = {}
        @lock = Mutex.new
        @sporadics = Set.new
        @default_tags = options.fetch(:default_tags, {})
      end

      # Retrieve the current value for a given metric. This is a short
      # form for convenience which only retrieves metrics with no custom
      # source specified. For more options see #fetch.
      #
      # @param [String|Symbol] key metric name
      # @return [Integer|Float] current value
      def [](key)
        fetch(key)
      end

      # removes all tracked metrics. note this removes all measurement
      # data AND metric names any continuously tracked metrics will not
      # report until they get another measurement
      def delete_all
        @lock.synchronize { @cache.clear }
      end

      def fetch(key, options={})
        key = key.to_s
        key =
          if options[:tags]
            Librato::Metrics::Util.build_key_for(key, options[:tags])
          elsif @default_tags
            Librato::Metrics::Util.build_key_for(key, @default_tags)
          end
        @lock.synchronize { @cache[key] }
      end

      # transfer all measurements to queue and reset internal status
      def flush_to(queue, opts={})
        counts = nil
        @lock.synchronize do
          # work off of a duplicate data set so we block for
          # as little time as possible
          # requires a deep copy of data set
          counts = JSON.parse(@cache.dup.to_json, symbolize_names: true)
          reset_cache unless opts[:preserve]
        end
        counts.each do |metric, payload|
          metric = metric.to_s.split(SEPARATOR).first
          queue.add metric => payload
        end
      end

      # Increment a given metric
      #
      # @example Increment metric 'foo' by 1
      #   increment :foo
      #
      # @example Increment metric 'bar' by 2
      #   increment :bar, :by => 2
      #
      # @example Increment metric 'foo' by 1 with a custom source
      #   increment :foo, :source => user.id
      #
      def increment(counter, options={})
        metric = counter.to_s
        if options.is_a?(Fixnum)
          # suppport legacy style
          options = {by: options}
        end
        by = options[:by] || 1
        source = options[:source]
        tags_option = options[:tags]
        tags_option = { source: source } if source && !tags_option
        tags =
          if tags_option && options[:inherit_tags]
            @default_tags.merge(tags_option)
          elsif tags_option
            tags_option
          else
            @default_tags
          end
        metric = Librato::Metrics::Util.build_key_for(metric, tags) if tags
        if options[:sporadic]
          make_sporadic(metric)
        end
        @lock.synchronize do
          @cache[metric] = {} unless @cache[metric]
          @cache[metric][:name] ||= metric
          @cache[metric][:value] ||= 0
          @cache[metric][:value] += by
          @cache[metric][:tags] = tags if tags
        end
      end

      private

      def make_sporadic(metric)
        @sporadics << metric
      end

      def reset_cache
        # remove any source/metric pairs that aren't continuous
        @sporadics.each { |metric| @cache.delete(metric) }
        @sporadics.clear
        # reset all continuous source/metric pairs to 0
        @cache.each_key { |key| @cache[key][:value] = 0 }
      end

    end

  end
end
