module RollupEngine
  module Recompute
    def self.call(measure_name, facts, grain:, time:, by: [])
      result = Rollup.compute(facts, measure: measure_name, grain: grain, time: time, by: by)

      result.each do |key, value|
        period_start, dimensions = decompose(key, by)
        datapoint = Datapoint.find_or_initialize_by(
          measure: measure_name.to_s,
          grain: grain.to_s,
          period_start: period_start,
          dimensions_key: Datapoint.dimensions_key_for(dimensions)
        )
        datapoint.update!(dimensions: dimensions, value: value, recomputed_at: Time.current)
      end
    end

    def self.decompose(key, by)
      return [ key, {} ] if by.empty?

      period_start, *dimension_values = key
      names = by.is_a?(Hash) ? by.keys : by
      [ period_start, names.map(&:to_s).zip(dimension_values).to_h ]
    end
  end
end
