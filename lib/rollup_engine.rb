require "rollup_engine/version"
require "rollup_engine/engine"
require "rollup_engine/measure"
require "rollup_engine/rollup"
require "rollup_engine/recompute"

module RollupEngine
  class << self
    def measures
      @measures ||= {}
    end

    def recompute(measure_name, facts, grain:, time:, by: [])
      Recompute.call(measure_name, facts, grain: grain, time: time, by: by)
    end

    def register_measure(name, aggregation:, field: nil)
      measures[name] = Measure.new(name: name, aggregation: aggregation, field: field)
    end

    def measure(name)
      measures.fetch(name)
    end

    def reset_measures!
      measures.clear
    end
  end
end
