require 'hetchy'

module Librato
  class Collector
    # maintains storage of timing and measurement type measurements
    #
    class Aggregator
      SEPARATOR = "$$"

      extend Forwardable

      def_delegators :@cache, :empty?, :prefix, :prefix=, :tags, :tags=

      def initialize(options={})
        @cache = Librato::Metrics::Aggregator.new(
          prefix: options[:prefix],
          tags: options.fetch(:tags, {})
        )
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
        measurements = nil
        tags = options[:tags]
        @lock.synchronize { measurements = @cache.queued[:measurements] }
        measurements.each do |metric|
          if metric[:name] == key.to_s
            return metric if !tags && !metric[:tags]
            return metric if tags == metric[:tags]
          end
        end
        nil
      end

      # clear all stored values
      def delete_all
        @lock.synchronize { clear_storage }
      end

      # transfer all measurements to queue and reset internal status
      def flush_to(queue, opts={})
        queued = nil
        @lock.synchronize do
          return if @cache.empty?
          queued = @cache.queued
          flush_percentiles(queue, opts) unless @percentiles.empty?
          clear_storage unless opts[:preserve]
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

        if options[:source]
          # convert custom instrumentation using legacy source
          tags = { source: options[:source] }
        end

        tags = options[:tags]
        percentiles = Array(options[:percentile])

        @lock.synchronize do
          payload = { value: value }
          payload.merge!({ tags: tags }) if tags
          @cache.add event => payload

          percentiles.each do |perc|
            store = fetch_percentile_store(event, payload)
            store[:reservoir] << value
            track_percentile(store, perc)
          end
        end
        returned
      end
      alias :timing :measure

      private

      def clear_storage
        @cache.clear
        @percentiles.each do |key, val|
          val[:reservoir].clear
          val[:percs].clear
        end
      end

      def fetch_percentile(key, options)
        store = fetch_percentile_store(key, options[:tags])
        return nil unless store
        store[:reservoir].percentile(options[:percentile])
      end

      def fetch_percentile_store(event, options)
        keyname = event

        if options[:tags]
          keyname = Librato::Metrics::Util.build_key_for(keyname, options[:tags])
        end

        @percentiles[keyname] ||= {
          name: event,
          reservoir: Hetchy::Reservoir.new(size: 1000),
          percs: Set.new
        }
        @percentiles[keyname].merge!({ tags: options[:tags] }) if options && options[:tags]
        @percentiles[keyname]
      end

      def flush_percentiles(queue, opts)
        @percentiles.each do |key, val|
          val[:percs].each do |perc|
            perc_name = perc.to_s[0,5].gsub('.','')
            payload =
              if val[:tags]
                { value: val[:reservoir].percentile(perc), tags: val[:tags] }
              else
                val[:reservoir].percentile(perc)
              end
            queue.add "#{val[:name]}.p#{perc_name}" => payload
          end
        end
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
