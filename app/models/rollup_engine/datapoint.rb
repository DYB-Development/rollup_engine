require "json"

module RollupEngine
  class Datapoint < ApplicationRecord
    self.table_name = "rollup_engine_datapoints"

    scope :in_period, ->(range) { where(period_start: range) }

    before_validation :assign_dimensions_key

    # A canonical, order-independent string for a dimensions hash, used to match
    # and uniquely index rows. Avoids relying on JSON column equality, which
    # Postgres's `json` type does not support.
    def self.dimensions_key_for(dimensions)
      (dimensions || {}).to_a.sort.to_h.to_json
    end

    def self.series(measure, range)
      where(measure: measure.to_s).in_period(range).group(:period_start).order(:period_start).sum(:value).to_a
    end

    private

    def assign_dimensions_key
      self.dimensions_key = self.class.dimensions_key_for(dimensions)
    end
  end
end
