module Librato
  class Rack
    class Configuration

      class Suites
        attr_reader :fields
        def initialize(value)
          @fields = value.to_s.split(/\s*,\s*/).map(&:to_sym)
        end

        def include?(field)
          fields.include?(field)
        end
      end

      class SuitesAll
        def include?(value)
          true
        end
      end

      class SuitesExcept < Suites
        DEFAULT_SUITES = [:rack]

        def initialize(value)
          super
          @fields = DEFAULT_SUITES - @fields
        end

        def include?(field)
          fields.include?(field)
        end
      end

      class SuitesNone
        def include?(value)
          false
        end
      end

    end
  end
end