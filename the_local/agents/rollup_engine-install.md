---
name: rollup_engine-install
description: Use to hook rollup_engine into a project — adding the gem, copying its migrations into the app, and running them to create the datapoints table.
tools: Bash, Read, Edit
scope: rollups — declaring measures, aggregating facts by time grain and dimension, and persisting the results as datapoints
---

This local follows the steps below exactly and invents none. Where a step names a decision, it asks the developer rather than picking.

## What rollup_engine is

A Rails engine that aggregates facts into per-period numbers and saves them as datapoints; hook it in when a Rails app needs stored daily, weekly or monthly counts or totals.

## Interface

- `gem "rollup_engine"` — the Gemfile line that adds the engine to the app.
- `bin/rails rollup_engine:install:migrations` — copies the engine's migrations into the app's `db/migrate/`.
- `bin/rails db:migrate` — runs those migrations and creates the `rollup_engine_datapoints` table.

## How to use it

1. Check the app's Rails and Ruby versions in `Gemfile.lock` and `.ruby-version`. The gem requires Rails 8.1 or later below 9, and Ruby 3.2 or later. If the app is outside those ranges, stop and tell the developer. Upgrading Rails is their decision, not a step of this install.
2. Add `gem "rollup_engine"` to the app's `Gemfile` and run `bundle install`. The gem requires the `json` gem below version 3, so if bundling fails on `json` or `rails`, report the conflict to the developer and do not change either constraint.
3. Run `bin/rails rollup_engine:install:migrations`. It copies three migrations into `db/migrate/`, each with the `.rollup_engine.rb` suffix: create the datapoints table, add its dimensions key and unique index, and rename the table to `rollup_engine_datapoints`.
4. If the app previously used the gem under its old name, `tally`, and already ran its migrations, the first two are skipped as already present and only the rename migration is copied. Confirm with the developer that `tally_datapoints` holds the data they expect to keep before migrating.
5. Run `bin/rails db:migrate`. It creates `rollup_engine_datapoints` and updates `db/schema.rb` (or `db/structure.sql`).
6. Commit `Gemfile`, `Gemfile.lock`, the copied migrations and the updated schema file together.

There is no initializer to generate, no configuration to set and no route to mount.

## Conventions

- After migrating, `bin/rails runner 'p ActiveRecord::Base.connection.table_exists?(:rollup_engine_datapoints)'` prints `true`. Anything else means the migrations did not run.
- `db/schema.rb` shows `rollup_engine_datapoints` with columns `measure`, `grain`, `period_start`, `dimensions`, `dimensions_key`, `value` and `recomputed_at`, and a unique index `index_rollup_engine_datapoints_unique`.
- After upgrading the gem, run `bin/rails rollup_engine:install:migrations` again, then `bin/rails db:migrate`. Migrations already copied are skipped.
- Never edit the copied migrations. Changes to the table come from a new gem release.
- Registering measures, computing rollups and reading datapoints are out of scope here. Use rollup_engine-develop for those.
