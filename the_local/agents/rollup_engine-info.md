---
name: rollup_engine-info
description: Use to learn what rollup_engine offers — measures, facts, time grains, dimensions, rollups, and the datapoints they are saved as.
tools: Read
scope: rollups — declaring measures, aggregating facts by time grain and dimension, and persisting the results as datapoints
---

This local explains rollup_engine and the words it uses. It makes no changes and gives no steps.

## What rollup_engine is

rollup_engine is a Rails engine, for apps on Rails 8.1 or later within 8.x, that turns a collection of records into numbers per time period. You give it facts, name a measure, pick a time grain and optionally some dimensions, and it returns one number per period and dimension combination. It can also save those numbers to its own table, and running the same computation again updates the saved rows rather than adding new ones.

It does not care where the facts come from. Anything that can be enumerated and read from works: ActiveRecord rows, plain Ruby objects, or stored events whose values sit inside a JSON payload. Reach for it when an app needs daily, weekly or monthly totals or counts, split by attributes such as channel or plan, and wants those totals stored for charts and reports instead of computed on every request.

## Interface

rollup_engine declares no commands for this local. Its surface belongs to the other two:

- **rollup_engine-install** owns adding the gem to an app and creating its datapoints table.
- **rollup_engine-develop** owns registering measures, computing rollups, saving them, and reading saved datapoints back as a series.

## How to use it

- The app does not have rollup_engine yet, or its datapoints table is missing: use **rollup_engine-install**.
- The app has it and you need to define a measure, compute or save a rollup, or query saved results: use **rollup_engine-develop**.

## Conventions

- **Fact** — one input record. A fact only needs a time value and whatever the measure and dimensions read from it.
- **Measure** — a named number defined once by name, such as `:revenue` or `:signups`. Its aggregation is either `count`, which counts facts, or `sum`, which adds up one field of each fact. Measures are registered in memory for the running process, not stored in the database.
- **Grain** — the size of the time period facts are grouped into, such as `day`, `week`, `month` or `year`. Each fact falls into the period that starts at the beginning of its grain.
- **Dimension** — an attribute facts are split by, such as a channel. With no dimensions, there is one number per period.
- **Named dimension** — a dimension given as a name paired with an accessor rather than as a method name alone. The name is what the dimension is saved under, so a dimension read with a lambda needs one.
- **Accessor** — how a time, field or dimension is read from a fact: either the name of a method on the fact, or a lambda that takes the fact and returns the value. A lambda is how values nested in a JSON payload are reached.
- **Rollup** — the computed result: one value per period, or per period and dimension combination. Computing a rollup saves nothing.
- **Datapoint** — one saved rollup value, identified by its measure, grain, period start and dimension values. Dimension names are stored as strings, and the order dimensions were given in does not change which row matches.
- **Recompute** — computing a rollup and saving it as datapoints. Running it again over the same facts updates the existing datapoints in place and records when they were last recomputed.
- **Series** — the saved values for one measure over a date range, as one total per period start, summed across all dimension combinations. A series does not filter by grain, so a measure saved at more than one grain has those values added together wherever their period starts coincide.
