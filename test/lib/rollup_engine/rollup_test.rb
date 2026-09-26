require "test_helper"

module RollupEngine
  class RollupTest < ActiveSupport::TestCase
    Fact = Struct.new(:occurred_at, :amount, :channel, keyword_init: true)

    test "counts facts within a single time bucket" do
      facts = [
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 10)),
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 15))
      ]

      result = Rollup.count(facts, grain: :day, time: :occurred_at)

      assert_equal({ Time.utc(2026, 6, 1) => 2 }, result)
    end

    test "sums a measure field within a time bucket" do
      facts = [
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 10), amount: 100),
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 15), amount: 50)
      ]

      result = Rollup.sum(facts, :amount, grain: :day, time: :occurred_at)

      assert_equal({ Time.utc(2026, 6, 1) => 150 }, result)
    end

    test "buckets by a dimension alongside time" do
      facts = [
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 10), channel: "web"),
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 11), channel: "web"),
        Fact.new(occurred_at: Time.utc(2026, 6, 1, 12), channel: "app")
      ]

      result = Rollup.count(facts, grain: :day, time: :occurred_at, by: [ :channel ])

      assert_equal(
        { [ Time.utc(2026, 6, 1), "web" ] => 2, [ Time.utc(2026, 6, 1), "app" ] => 1 },
        result
      )
    end

    test "extracts the bucketing time via a callable" do
      facts = [ { at: Time.utc(2026, 6, 1, 10) }, { at: Time.utc(2026, 6, 1, 15) } ]

      result = Rollup.count(facts, grain: :day, time: ->(fact) { fact[:at] })

      assert_equal({ Time.utc(2026, 6, 1) => 2 }, result)
    end

    test "extracts a dimension via a callable" do
      facts = [
        { at: Time.utc(2026, 6, 1, 10), data: { "ch" => "web" } },
        { at: Time.utc(2026, 6, 1, 11), data: { "ch" => "app" } }
      ]

      result = Rollup.count(
        facts,
        grain: :day,
        time: ->(fact) { fact[:at] },
        by: [ ->(fact) { fact[:data]["ch"] } ]
      )

      assert_equal(
        { [ Time.utc(2026, 6, 1), "web" ] => 1, [ Time.utc(2026, 6, 1), "app" ] => 1 },
        result
      )
    end

    test "sums a measure field via a callable" do
      facts = [
        { at: Time.utc(2026, 6, 1, 10), payload: { "amount" => 100 } },
        { at: Time.utc(2026, 6, 1, 15), payload: { "amount" => 50 } }
      ]

      result = Rollup.sum(
        facts,
        ->(fact) { fact[:payload]["amount"] },
        grain: :day,
        time: ->(fact) { fact[:at] }
      )

      assert_equal({ Time.utc(2026, 6, 1) => 150 }, result)
    end

    test "extracts a named dimension via a callable" do
      facts = [
        { at: Time.utc(2026, 6, 1, 10), data: { "ch" => "web" } },
        { at: Time.utc(2026, 6, 1, 11), data: { "ch" => "app" } }
      ]

      result = Rollup.count(
        facts,
        grain: :day,
        time: ->(fact) { fact[:at] },
        by: { channel: ->(fact) { fact[:data]["ch"] } }
      )

      assert_equal(
        { [ Time.utc(2026, 6, 1), "web" ] => 1, [ Time.utc(2026, 6, 1), "app" ] => 1 },
        result
      )
    end
  end
end
