module Librato
  class Rack
    class Configuration

      class Suites
        attr_reader :fields
        def initialize(value, defaults)
          @fields = if value.nil? || value.empty?
                      defaults
                    else
                      resolve_suites(value, defaults)
                    end
        end

        def include?(field)
          fields.include?(field)
        end

        private

        def resolve_suites(value, defaults)
          suites = value.to_s.split(/\s*,\s*/)
          adds = suites.select { |i| i.start_with?('+') }.map { |i| i[1..-1].to_sym }
          subs = suites.select { |i| i.start_with?('-') }.map { |i| i[1..-1].to_sym }

          if adds.any? || subs.any?

            # Did they try to mix adds/subs with explicit config
            if (adds.size + subs.size) != suites.size
              raise InvalidSuiteConfiguration, "Invalid suite value #{value}"
            end

            (defaults | adds) - subs
          else
            suites.map(&:to_sym)
          end
        end
      end

      class SuitesAll
        def fields; [:all]; end

        def include?(value)
          true
        end
      end

      class SuitesNone
        def fields; []; end

        def include?(value)
          false
        end
      end

    end
  end
end
