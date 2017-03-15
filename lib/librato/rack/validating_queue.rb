module Librato
  class Rack
    # Queue with special upfront validating logic, this should
    # probably be available in librato-metrics but spiking here
    # to work out the kinks
    #
    class ValidatingQueue < Librato::Metrics::Queue
      DEFAULT_TAGS_LIMIT = 4
      METRIC_NAME_REGEX = /\A[-.:_\w]{1,255}\z/
      TAGS_KEY_REGEX = /\A[-.:_\w]{1,64}\z/
      TAGS_VALUE_REGEX = /\A[-.:_\w\s]{1,255}\z/

      attr_accessor :logger

      def submit
        validate_measurements

        super
      end

      # screen all measurements for validity before sending
      def validate_measurements
        @queued[:measurements].delete_if do |entry|
          name = entry[:name].to_s
          tags = entry[:tags]
          if name !~ METRIC_NAME_REGEX
            log :warn, "invalid metric name '#{name}', not sending."
            true # delete
          elsif tags && tags.any? { |k,v| k.to_s !~ TAGS_KEY_REGEX || v.to_s !~ TAGS_VALUE_REGEX }
            log :warn, "halting: '#{tags}' are invalid tags."
            true # delete
          else
            false # preserve
          end
        end
      end

      private

      def log(level, msg)
        return unless logger
        logger.log level, msg
      end

    end
  end
end
