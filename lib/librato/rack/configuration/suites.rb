module Librato
  class Rack
    class Configuration

      DEFAULT_SUITES = [:rack, :rack_method, :rack_status]

      class Suites
        attr_reader :fields
        def initialize(value)
          @fields = if value.nil? || value.empty?
                      DEFAULT_SUITES
                    else
                      value.to_s.split(/\s*,\s*/).map(&:to_sym)
                    end
        end

        def include?(field)
          fields.include?(field)
        end
      end

      class SuitesInclude < Suites
        def initialize(value)
          super
          @fields = DEFAULT_SUITES + @fields
        end
      end

      class SuitesExcept < Suites
        def initialize(value)
          super
          @fields = DEFAULT_SUITES - @fields
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
