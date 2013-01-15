module Librato
  class Collector
    # abstracts grouping together several similarly named measurements
    #
    class Group

      def initialize(collector, prefix)
        @collector, @prefix = collector, "#{prefix}."
      end

      def group(prefix)
        prefix = "#{@prefix}#{prefix}"
        yield self.class.new(@collector, prefix)
      end

      def increment(counter, by=1)
        counter = "#{@prefix}#{counter}"
        @collector.increment counter, by
      end

      def measure(event, duration)
        event = "#{@prefix}#{event}"
        @collector.measure event, duration
      end
      alias :timing :measure

    end
  end
end