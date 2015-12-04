require 'forwardable'

module Librato
  # collects and stores measurement values over time so they can be
  # reported periodically to the Metrics service
  #
  class Collector
    extend Forwardable

    def initialize(options={})
      @source_prefix = options[:source_prefix]
    end

    def increment(counter, options={})
      if @source_prefix && options[:source]
        options[:source] = "#{@source_prefix}.#{options[:source]}"
      end
      counters.increment(counter, options)
    end

    def measure(*args, &block)
      if args.length > 1 and args[-1].respond_to?(:each)
        options = args[-1]
        if @source_prefix && options[:source]
          options[:source] = "#{@source_prefix}.#{options[:source]}"
        end
      end
      aggregate.measure(*args, &block)
    end
    alias :timing :measure

    # access to internal aggregator object
    def aggregate
      @aggregator_cache ||= Aggregator.new(prefix: @prefix)
    end

    # access to internal counters object
    def counters
      @counter_cache ||= CounterCache.new
    end

    # remove any accumulated but unsent metrics
    def delete_all
      aggregate.delete_all
      counters.delete_all
    end
    alias :clear :delete_all

    def group(prefix)
      group = Group.new(self, prefix)
      yield group
    end

    # update prefix
    def prefix=(new_prefix)
      @prefix = new_prefix
      aggregate.prefix = @prefix
    end

    def prefix
      @prefix
    end

  end
end

require_relative 'collector/aggregator'
require_relative 'collector/counter_cache'
require_relative 'collector/exceptions'
require_relative 'collector/group'
