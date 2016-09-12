module Librato
  class Collector
    # maintains storage of a set of incrementable, counter-like
    # measurements
    #
    class CounterCache
      SEPARATOR = '%%'

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
        key = key.to_s
        if options[:tags] && options[:tags].respond_to?(:each)
          options[:tags].sort.each do |k, v|
            k = k.is_a?(String) ? k.downcase.delete(" ") : k
            v = v.is_a?(String) ? v.downcase.delete(" ") : v
            key = "#{key}#{SEPARATOR}#{k}#{SEPARATOR}#{v}"
          end
        end
        @lock.synchronize do
          if @cache[key] && @cache[key].respond_to?(:each)
            # return value for backwards compatibility
            @cache[key][:value]
          else
            @cache[key]
          end
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
          metric = metric.split(SEPARATOR).first
          queue.add metric => value
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
        tags = {}
        metric = counter.to_s
        if options.is_a?(Fixnum)
          # suppport legacy style
          options = {by: options}
        end
        by = options[:by] || 1
        if options[:tags] && options[:tags].respond_to?(:each)
          options[:tags].sort.each do |k, v|
            k = k.is_a?(String) ? k.downcase.delete(' ') : k
            v = v.is_a?(String) ? v.downcase.delete(' ') : v
            metric = "#{metric}#{SEPARATOR}#{k}#{SEPARATOR}#{v}"
          end
        end
        tags.merge!(options[:tags]) if options[:tags]
        if options[:sporadic]
          make_sporadic(metric)
        end
        @lock.synchronize do
          @cache[metric] = {} unless @cache[metric]
          @cache[metric][:name] ||= counter.to_s
          @cache[metric][:value] ||= 0
          @cache[metric][:value] += by
          @cache[metric][:tags] = tags unless tags.empty?
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
        @cache.each_key { |key| @cache[key] = { value: 0 } }
      end

    end

  end
end
