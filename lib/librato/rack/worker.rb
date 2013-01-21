module Librato
  class Rack
    # Runs a given piece of code periodically, ensuring that
    # it will be run again at the proper interval regardless
    # of how long execution takes.
    #
    class Worker

      def initialize
        @interrupt = false
      end

      # run the given block every <period> seconds, looping
      # infinitely unless @interrupt becomes true.
      #
      def run_periodically(period, &block)
        next_run = start_time(period)
        until @interrupt do
          now = Time.now
          if now >= next_run
            block.call
            while next_run <= now
              next_run += period
            end
          else
            sleep(next_run - now)
          end
        end
      end

      # Give some structure to worker start times so when possible
      # they will be in sync.
      def start_time(period)
        earliest = Time.now + period
        # already on a whole minute
        return earliest if earliest.sec == 0
        if period > 30
          # bump to whole minute
          earliest + (60-earliest.sec)
        else
          # ensure sync to whole minute if minute is evenly divisible
          earliest + (period-(earliest.sec%period))
        end
      end

    end

  end
end
