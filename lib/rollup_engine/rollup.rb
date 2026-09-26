module RollupEngine
  module Rollup
    def self.compute(facts, measure:, grain:, time:, by: [])
      definition = RollupEngine.measure(measure)

      case definition.aggregation
      when :count then count(facts, grain: grain, time: time, by: by)
      when :sum then sum(facts, definition.field, grain: grain, time: time, by: by)
      else raise ArgumentError, "Unknown aggregation: #{definition.aggregation.inspect}"
      end
    end

    def self.count(facts, grain:, time:, by: [])
      grouped(facts, grain, time, by).transform_values(&:size)
    end

    def self.sum(facts, field, grain:, time:, by: [])
      grouped(facts, grain, time, by).transform_values do |group|
        group.sum { |fact| extract(fact, field) }
      end
    end

    def self.grouped(facts, grain, time, by)
      facts.group_by { |fact| key(fact, grain, time, by) }
    end

    def self.key(fact, grain, time, by)
      bucket = bucket(extract(fact, time), grain)
      return bucket if by.empty?

      accessors = by.is_a?(Hash) ? by.values : by
      [ bucket, *accessors.map { |accessor| extract(fact, accessor) } ]
    end

    def self.extract(fact, accessor)
      accessor.respond_to?(:call) ? accessor.call(fact) : fact.public_send(accessor)
    end

    def self.bucket(moment, grain)
      moment.public_send("beginning_of_#{grain}")
    end
  end
end
