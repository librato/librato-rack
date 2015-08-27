require 'hetchy'

module Librato
  class Collector
    # maintains storage of timing and measurement type measurements
    #
    class Aggregator
      SOURCE_SEPARATOR = '$$'

      extend Forwardable

      def_delegators :@cache, :empty?, :prefix, :prefix=

      def initialize(options={})
        @cache = Librato::Metrics::Aggregator.new(prefix: options[:prefix])
        @percentiles = {}
        @lock = Mutex.new
      end

      def [](key)
        fetch(key)
      end

      # retrieve current value of a metric/source/percentage. this exists
      # primarily for debugging/testing and isn't called routinely.
      def fetch(key, options={})
        return nil if @cache.empty?
        return fetch_percentile(key, options) if options[:percentile]
        gauges = nil
        source = options[:source]
        @lock.synchronize { gauges = @cache.queued[:gauges] }
        gauges.each do |metric|
          if metric[:name] == key.to_s
            return metric if !source && !metric[:source]
            return metric if source.to_s == metric[:source]
          end
        end
        nil
      end

      # clear all stored values
      def delete_all
        @lock.synchronize {
          @cache.clear
          @percentiles = {}
        }
      end

      # transfer all measurements to queue and reset internal status
      def flush_to(queue, opts={})
        queued = nil
        @lock.synchronize do
          return if @cache.empty?
          queued = @cache.queued
          flush_percentiles(queue, opts) unless @percentiles.empty?
          @cache.clear unless opts[:preserve]
        end
        queue.merge!(queued) if queued
      end

      # @example Simple measurement
      #   measure 'sources_returned', sources.length
      #
      # @example Simple timing in milliseconds
      #   timing 'twitter.lookup', 2.31
      #
      # @example Block-based timing
      #   timing 'db.query' do
      #     do_my_query
      #   end
      #
      # @example Custom source
      #    measure 'user.all_orders', user.order_count, :source => user.id
      #
      def measure(*args, &block)
        options = {}
        event = args[0].to_s
        returned = nil

        # handle block or specified argument
        if block_given?
          start = Time.now
          returned = yield
          value = ((Time.now - start) * 1000.0).to_i
        elsif args[1]
          value = args[1]
        else
          raise "no value provided"
        end

        # detect options hash if present
        if args.length > 1 and args[-1].respond_to?(:each)
          options = args[-1]
        end
        source = options[:source]
        percentiles = Array(options[:percentile])

        @lock.synchronize do
          if source
            @cache.add event => {source: source, value: value}
          else
            @cache.add event => value
          end

          percentiles.each do |perc|
            store = fetch_percentile_store(event, source)
            store[:reservoir] << value
            track_percentile(store, perc)
          end
        end
        returned
      end
      alias :timing :measure

      private

      def fetch_percentile(key, options)
        store = fetch_percentile_store(key, options[:source])
        return nil unless store
        store[:reservoir].percentile(options[:percentile])
      end

      def fetch_percentile_store(event, source)
        keyname = source ? "#{event}#{SOURCE_SEPARATOR}#{source}" : event
        @percentiles[keyname] ||= {
          reservoir: Hetchy::Reservoir.new(size: 1000),
          percs: Set.new
        }
      end

      def flush_percentiles(queue, opts)
        @percentiles.each do |key, val|
          metric, source = key.split(SOURCE_SEPARATOR)
          val[:percs].each do |perc|
            perc_name = perc.to_s[0,5].gsub('.','')
            payload = if source
              { value: val[:reservoir].percentile(perc), source: source }
            else
              val[:reservoir].percentile(perc)
            end
            queue.add "#{metric}.p#{perc_name}" => payload
          end
        end
        @percentiles = {} unless opts[:preserve]
      end

      def track_percentile(store, perc)
        if perc < 0.0 || perc > 100.0
          raise InvalidPercentile, "Percentiles must be between 0.0 and 100.0"
        end
        store[:percs].add(perc)
      end

    end

  end
end