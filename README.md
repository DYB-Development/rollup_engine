# RollupEngine

A **source-agnostic aggregation engine**. Feed it facts — rows with dimensions and
measurable values — and it turns them into numbers: declared **measures**, rolled up
by **time grain** and **dimension**, recomputed idempotently.

RollupEngine depends on no particular data source. It doesn't know about events, an outbox,
or any specific producer — anything that can hand it facts can use it. (In the
EventEngine stack, an adapter feeds `event_engine-store` events in as facts; but
that adapter lives elsewhere, not here.)

## Installation

```ruby
gem "rollup_engine"
```

```bash
$ bundle
```

## Status

Early development. The first rollup works — `RollupEngine::Rollup.count` / `.sum` aggregate
facts by **time grain** and optional **dimensions**:

```ruby
RollupEngine::Rollup.count(facts, grain: :day, time: :occurred_at)
RollupEngine::Rollup.sum(facts, :amount, grain: :day, time: :occurred_at, by: [:channel])
```

Declare named **measures** once and compute by name:

```ruby
RollupEngine.register_measure(:revenue, aggregation: :sum, field: :amount)
RollupEngine::Rollup.compute(facts, measure: :revenue, grain: :day, time: :occurred_at)
```

Persist rollups idempotently into the `rollup_engine_datapoints` table:

```ruby
RollupEngine.recompute(:revenue, facts, grain: :day, time: :occurred_at, by: [:channel])
# upserts one RollupEngine::Datapoint per (measure, grain, period_start, dimensions);
# re-running updates values in place — no duplicates.
```

`time`, `field`, and dimensions accept a **method symbol or a callable**, so facts
with nested data roll up without a wrapper — e.g. an event's JSON `payload`:

```ruby
RollupEngine.recompute(:revenue, stored_events,
  grain: :day,
  time:  :occurred_at,
  field: ->(e) { e.payload["amount"] },
  by:    [ ->(e) { e.payload["channel"] } ])
```

This is what lets `event_engine-store` events feed `rollup_engine` without coupling the two.

Next: a recompute job + window scoping, then sketches/cohorts.

## License

Available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
