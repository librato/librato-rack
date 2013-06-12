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
        @proc = block

        if em_synchrony_mode? or eventmachine_mode?
          compensated_repeat(period)
        else
          @thread = Thread.new { compensated_repeat(period) }
        end
      end

      # Give some structure to worker start times so when possible
      # they will be in sync.
      #
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

      def kill_thread
        Thread.kill(@thread)
      end

      private

      def compensated_repeat(period, first_run = nil)
        next_run = first_run || start_time(period)
        until @interrupt do
          now = Time.now
          if now >= next_run
            @proc.call

            while next_run <= now
              next_run += period # schedule future run
            end
          end

          interval = next_run - now
          if eventmachine_mode?
            EM.add_timer(interval) { compensated_repeat(period, next_run) }
            break
          elsif em_synchrony_mode?
            EM::Synchrony.sleep(interval)
          else
            sleep(next_run - now)
          end
        end
      end

      def em_synchrony_mode?
        ENV['LIBRATO_NETWORK_MODE'] == 'synchrony'
      end

      def eventmachine_mode?
        ENV['LIBRATO_NETWORK_MODE'] == 'eventmachine'
      end

    end
  end
end
