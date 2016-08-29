module Librato
  class Rack
    # Queue with special upfront validating logic, this should
    # probably be available in librato-metrics but spiking here
    # to work out the kinks
    #
    class ValidatingQueue < Librato::Metrics::Queue
      METRIC_NAME_REGEX = /\A[-.:_\w]{1,255}\z/

      attr_accessor :logger

      # screen all measurements for validity before sending
      def submit
        @queued[:measurements].delete_if do |entry|
          name = entry[:name].to_s
          if name !~ METRIC_NAME_REGEX
            log :warn, "invalid metric name '#{name}', not sending."
            true # delete
          else
            false # preserve
          end
        end

        super
      end

      private

      def log(level, msg)
        return unless logger
        logger.log level, msg
      end

    end
  end
end
