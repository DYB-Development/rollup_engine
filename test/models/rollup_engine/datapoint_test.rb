require "test_helper"

module RollupEngine
  class DatapointTest < ActiveSupport::TestCase
    test "in_period returns only datapoints whose period_start falls in the range" do
      inside = Datapoint.create!(measure: "leads", grain: "day", period_start: Time.utc(2026, 6, 10), value: 5, dimensions: {})
      Datapoint.create!(measure: "leads", grain: "day", period_start: Time.utc(2026, 5, 31), value: 3, dimensions: {})

      result = Datapoint.in_period(Time.utc(2026, 6, 1)..Time.utc(2026, 6, 30))

      assert_equal [ inside ], result.to_a
    end

    test "series sums a measure per period within the range, ordered by period" do
      Datapoint.create!(measure: "leads", grain: "day", period_start: Time.utc(2026, 6, 2), value: 5, dimensions: { "channel" => "web" })
      Datapoint.create!(measure: "leads", grain: "day", period_start: Time.utc(2026, 6, 2), value: 3, dimensions: { "channel" => "ads" })
      Datapoint.create!(measure: "leads", grain: "day", period_start: Time.utc(2026, 6, 1), value: 2, dimensions: {})
      Datapoint.create!(measure: "leads", grain: "day", period_start: Time.utc(2026, 5, 30), value: 9, dimensions: {})

      series = Datapoint.series("leads", Time.utc(2026, 6, 1)..Time.utc(2026, 6, 30))

      assert_equal [ [ Time.utc(2026, 6, 1), 2 ], [ Time.utc(2026, 6, 2), 8 ] ], series
    end
  end
end
