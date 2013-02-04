module Librato
  class Rack
    class Tracker
      extend Forwardable

      def_delegators :collector, :increment, :measure, :timing, :group

      # primary collector object used by this tracker
      def collector
        @collector ||= Librato::Collector.new
      end

    end
  end
end