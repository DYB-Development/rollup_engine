---
name: rollup_engine-develop
description: Use PROACTIVELY for declaring a counted or summed measure, rolling records up into daily, weekly or monthly buckets split by dimension, saving those totals as datapoints, and reading a time series back for a chart or report — MUST BE USED instead of hand-rolling group_by-and-sum code, per-period count queries or a custom stats table.
tools: Read, Write, Edit, Grep
scope: rollups — declaring measures, aggregating facts by time grain and dimension, and persisting the results as datapoints
---

This local follows the steps below exactly and invents none. Where a step names a decision, it asks the developer rather than picking.

## What rollup_engine is

A Rails engine that turns a collection of records ("facts") into one number per time bucket, optionally split by dimensions, and saves each number as a `RollupEngine::Datapoint` row. Use this local when an app needs stored counts or totals per day, week, month or other period, or needs to read such a series back.

## Interface

- `RollupEngine.register_measure` — declares a named measure as a count of facts or a sum of one field.
- `RollupEngine.recompute` — rolls facts up for a measure and saves one datapoint per bucket, updating existing rows in place.
- `RollupEngine.reset_measures!` — clears every registered measure, for test isolation.
- `RollupEngine::Rollup.compute` — rolls facts up for a registered measure and returns the totals as a hash without saving.
- `RollupEngine::Rollup.count` — counts facts per bucket without a registered measure and returns a hash.
- `RollupEngine::Rollup.sum` — sums one field of the facts per bucket without a registered measure and returns a hash.
- `RollupEngine::Datapoint` — the ActiveRecord model holding saved rollups, one row per measure, grain, period and dimension combination.
- `RollupEngine::Datapoint.series` — returns `[period_start, total]` pairs for one measure over a time range, in period order.
- `RollupEngine::Datapoint.in_period` — scope limiting datapoints to those whose period starts inside a range.

## How to use it

1. Put these decisions to the developer before writing code. Do not pick for them.
   - Which records are the facts, and which time attribute places each one in a bucket (for example `created_at` or `paid_at`).
   - Whether each measure counts facts or sums a numeric field, and which field.
   - The grain: `:day`, `:week`, `:month`, `:quarter` or `:year` (also `:hour` or `:minute`). Any name works for which the time value answers `beginning_of_<grain>`. `:week` starts on the app's configured `beginning_of_week`, Monday by default.
   - Which dimensions, if any, to split each bucket by (for example `:region` or `:plan`), what name each is saved under, and how its value is read from a fact.
   - When recomputing runs: after each write, in a scheduled job, or on demand.

2. Register each measure once at boot, in an initializer such as `config/initializers/rollup_engine.rb`:

   ```ruby
   RollupEngine.register_measure(:signups, aggregation: :count)
   RollupEngine.register_measure(:revenue, aggregation: :sum, field: :amount_cents)
   ```

   - `name` is the key every later call looks the measure up by. Use a symbol and pass that same symbol everywhere; a string and a symbol are different keys, and an unregistered name raises `KeyError`.
   - `aggregation:` is `:count` or `:sum`. Anything else is accepted at registration and raises `ArgumentError` when the measure is first computed.
   - `field:` is required for `:sum` and ignored for `:count`. It is a method name the fact responds to, or a lambda taking the fact and returning a number.
   - Registering the same name again replaces the earlier definition.

3. Recompute and save datapoints with `RollupEngine.recompute(measure_name, facts, grain:, time:, by: [])`:

   ```ruby
   RollupEngine.recompute(:signups, User.where(created_at: range), grain: :day, time: :created_at)
   RollupEngine.recompute(:revenue, Order.paid.where(paid_at: range), grain: :month, time: :paid_at, by: [:region])
   ```

   - `facts` is any enumerable of objects. An ActiveRecord relation is loaded into memory in full, so scope it to the periods being recomputed.
   - `time:` is a method name or a lambda taking the fact and returning a `Time`, `DateTime` or `Date`. Buckets start at the beginning of the grain in that value's own time zone.
   - `by:` is an array of method names, or a hash of dimension name to accessor. In an array each method name becomes a key in the saved `dimensions` hash, so an array holds names only, never lambdas.
   - When a dimension's value is not a method on the fact, or should be saved under a different name, pass a hash. Each key is the name saved in `dimensions` and each value is a method name or a lambda taking the fact:

     ```ruby
     RollupEngine.recompute(:revenue, orders, grain: :month, time: :paid_at, by: { region: ->(order) { order.address.region } })
     ```

     This saves `dimensions` as `{ "region" => "EU" }`.
   - Each bucket is matched on measure, grain, period start and dimension values. A matching row is updated with the new value and `recomputed_at`; otherwise a row is created. Running it twice on the same facts gives the same rows.
   - It only writes buckets that contain at least one fact. A bucket whose facts were all deleted keeps its old value. When facts can be removed, pass every fact in the affected periods, and delete stale rows for those periods before recomputing if the developer wants them gone.
   - Call it from wherever step 1 decided: a model callback, a job (for example `app/jobs/recompute_signups_job.rb`) or a rake task.

4. To get totals without saving, call `RollupEngine::Rollup.compute(facts, measure:, grain:, time:, by: [])` for a registered measure, or `RollupEngine::Rollup.count(facts, grain:, time:, by: [])` and `RollupEngine::Rollup.sum(facts, field, grain:, time:, by: [])` for a one-off. All three return a hash:
   - With `by: []`, each key is the bucket start time: `{ 2026-09-01 00:00 => 42 }`.
   - With dimensions, each key is an array of the bucket start followed by one value per dimension, in `by:` order: `{ [2026-09-01 00:00, "EU"] => 12 }`.
   - `by:` here may be an array of method names or lambdas taking the fact, or a hash of dimension name to accessor. The names in a hash do not appear in the result, only the values in the hash's order.
   - `count` values are integers. `sum` values are whatever adding the field values produces.

5. Read saved datapoints back.
   - `RollupEngine::Datapoint.series(:signups, from..to)` returns an array of `[period_start, total]` pairs ordered by period start, with `total` a `BigDecimal`. It adds up every row for that measure whose period starts in the range, across all grains and all dimension values. Record each measure at one grain, or query the model directly when it has more than one.
   - For one grain or one dimension value, query the model:

     ```ruby
     RollupEngine::Datapoint.where(measure: "revenue", grain: "month").in_period(from..to).order(:period_start)
     ```

   - Columns: `measure` (string), `grain` (string), `period_start` (datetime), `dimensions` (JSON hash with string keys, `{}` when there are none), `value` (decimal), `recomputed_at` (datetime).
   - `measure` and `grain` are stored as strings, so compare them with strings in `where`. `series` accepts a symbol or a string.
   - Filter on a dimension value in Ruby, for example `.select { |d| d.dimensions["region"] == "EU" }`, since equality on the JSON column is not supported on Postgres.

6. In tests, call `RollupEngine.reset_measures!` in setup or teardown and register the measures each test needs, so a measure registered by one test is not seen by another.

## Conventions

- Register a measure before calling `recompute` or `Rollup.compute` for it.
- Use the same symbol for a measure in `register_measure`, `recompute` and `Rollup.compute`.
- Recompute over every fact in the affected periods, never a partial set; each saved value replaces the old one rather than adding to it.
- Dimension values must be JSON-serializable, since they are saved in a JSON column.
- Never set `dimensions_key` on a datapoint. It is derived from `dimensions` on save.
- Write datapoints through `RollupEngine.recompute`, not by creating `RollupEngine::Datapoint` rows by hand.
- Adding the gem, copying its migrations and migrating are out of scope here. Use rollup_engine-install for those.
