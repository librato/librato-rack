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
        @period   = period
        @proc     = block
        @next_run = start_time(period)

        if em_synchrony_mode? or eventmachine_mode?
          compensated_repeat
          Thread.current # Err.. why am I doing this?
        else
          Thread.new do
            compensated_repeat
          end
        end
      end

      def compensated_repeat
        $log.d "compensated_repeat init.."
        unless @interrupt
          now = Time.now
          if now >= @next_run
            @proc.call
            $log.d "compensated_repeat complete!"
            while @next_run <= now
              @next_run += @period
            end

          else
            if eventmachine_mode?
              op = Proc.new { sleep(@next_run - now) }
              cb = Proc.new { compensated_repeat     }

              EM.defer(op, cb)

            elsif em_synchrony_mode?
              EM::Synchrony.sleep(@next_run - now)
              compensated_repeat

            else
              sleep(@next_run - now)
              compensated_repeat

            end
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

      def eventmachine_mode?
        ENV['LIBRATO_NETWORK_MODE'] and ENV['LIBRATO_NETWORK_MODE'] == 'eventmachine'
      end

      def em_synchrony_mode?
        ENV['LIBRATO_NETWORK_MODE'] and ENV['LIBRATO_NETWORK_MODE'] == 'synchrony'
      end
    end
  end
end
