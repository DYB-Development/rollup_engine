require "test_helper"

module RollupEngine
  class MeasureRegistryTest < ActiveSupport::TestCase
    Fact = Struct.new(:occurred_at, :amount, keyword_init: true)

    teardown do
      RollupEngine.reset_measures!
    end

    test "registers and looks up a measure by name" do
      RollupEngine.register_measure(:revenue, aggregation: :sum, field: :amount)

      assert_equal :sum, RollupEngine.measure(:revenue).aggregation
    end

    test "computes a rollup using a registered measure" do
      RollupEngine.register_measure(:revenue, aggregation: :sum, field: :amount)
      facts = [
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 10), amount: 100),
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 15), amount: 50)
      ]

      result = Rollup.compute(facts, measure: :revenue, grain: :day, time: :occurred_at)

      assert_equal({ Time.utc(2026, 6, 1) => 150 }, result)
    end
  end
end
