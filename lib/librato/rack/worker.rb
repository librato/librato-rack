module Librato
  class Rack
    # Runs a given piece of code periodically, ensuring that
    # it will be run again at the proper interval regardless
    # of how long execution takes.
    #
    class Worker
      attr_reader :timer

      # available options:
      #  * timer - type of timer to use, valid options are
      #            :sleep (default), :eventmachine, or :synchrony
      #  * sync  - try to synchronize timer executions to whole
      #            minutes or subdivisions thereof
      def initialize(options={})
        @interrupt = false
        @timer = (options[:timer] || :sleep).to_sym
        @sync = options[:sync] || false
      end

      # run the given block every <period> seconds, looping
      # infinitely unless @interrupt becomes true.
      #
      def run_periodically(period, &block)
        @proc = block # store

        if [:eventmachine, :synchrony].include?(timer)
          compensated_repeat(period) # threading is already handled
        else
          @thread = Thread.new { compensated_repeat(period) }
        end
      end

      # Give some structure to worker start times so when possible
      # they will be in sync.
      #
      def start_time(period)
        if @sync
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
        else
          if period > 30
            # ensure some wobble in start times,
            # trade a slightly irregular first period for a more even
            # distribution for network requests between processes
            start = Time.now
            start + (60-start.sec) + rand(60)
          else
            Time.now + period
          end
        end
      end

      # stop worker loop at the beginning of the next round
      # of execution
      def stop!
        @interrupt = true
      end

      private

      # run continuous loop executing every <period>, will start
      # at <first_run> if set otherwise will auto-determine
      # appropriate time for first run
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
          case timer
          when :eventmachine
            EM.add_timer(interval) { compensated_repeat(period, next_run) }
            break
          when :synchrony
            EM::Synchrony.sleep(interval)
          else
            sleep(next_run - now)
          end
        end
      end

    end
  end
end
