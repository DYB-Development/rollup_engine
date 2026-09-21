require "test_helper"

module RollupEngine
  class RecomputeTest < ActiveSupport::TestCase
    Fact = Struct.new(:occurred_at, :amount, :channel, keyword_init: true)

    teardown do
      RollupEngine.reset_measures!
    end

    test "persists a rollup datapoint" do
      RollupEngine.register_measure(:revenue, aggregation: :sum, field: :amount)
      facts = [
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 10), amount: 100),
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 15), amount: 50)
      ]

      RollupEngine.recompute(:revenue, facts, grain: :day, time: :occurred_at)

      assert_equal 150, Datapoint.sole.value
    end

    test "stamps recomputed_at" do
      RollupEngine.register_measure(:orders, aggregation: :count)

      RollupEngine.recompute(:orders, [ Fact.new(occurred_at: Time.utc(2026, 6, 1, 10)) ], grain: :day, time: :occurred_at)

      assert_not_nil Datapoint.sole.recomputed_at
    end

    test "re-running recompute upserts in place without duplicating" do
      RollupEngine.register_measure(:revenue, aggregation: :sum, field: :amount)
      facts = [ Fact.new(occurred_at: Time.utc(2026, 6, 1, 10), amount: 100) ]

      2.times { RollupEngine.recompute(:revenue, facts, grain: :day, time: :occurred_at) }

      assert_equal 1, Datapoint.count
    end

    test "upserts one datapoint per dimension value without duplicating" do
      RollupEngine.register_measure(:orders, aggregation: :count)
      facts = [
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 10), channel: "web"),
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 11), channel: "app")
      ]

      2.times { RollupEngine.recompute(:orders, facts, grain: :day, time: :occurred_at, by: [ :channel ]) }

      assert_equal 2, Datapoint.count
    end
  end
end
