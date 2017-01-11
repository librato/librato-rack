module Librato
  class Collector
    # maintains storage of a set of incrementable, counter-like
    # measurements
    #
    class CounterCache
      SEPARATOR = '%%'
      INTEGER_CLASS = 1.class

      extend Forwardable

      def_delegators :@cache, :empty?

      def initialize
        @cache = {}
        @lock = Mutex.new
        @sporadics = Set.new
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
        if options[:source]
          key = "#{key}#{SEPARATOR}#{options[:source]}"
        end
        @lock.synchronize do
          @cache[key.to_s]
        end
      end

      # transfer all measurements to queue and reset internal status
      def flush_to(queue, opts={})
        counts = nil
        @lock.synchronize do
          # work off of a duplicate data set so we block for
          # as little time as possible
          counts = @cache.dup
          reset_cache unless opts[:preserve]
        end
        counts.each do |metric, value|
          metric, source = metric.split(SEPARATOR)
          if source
            queue.add metric => {value: value, source: source}
          else
            queue.add metric => value
          end
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
        if options.is_a?(INTEGER_CLASS)
          # suppport legacy style
          options = {by: options}
        end
        by = options[:by] || 1
        if options[:source]
          metric = "#{counter}#{SEPARATOR}#{options[:source]}"
        else
          metric = counter.to_s
        end
        if options[:sporadic]
          make_sporadic(metric)
        end
        @lock.synchronize do
          @cache[metric] ||= 0
          @cache[metric] += by
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
        @cache.each_key { |key| @cache[key] = 0 }
      end

    end

  end
end
