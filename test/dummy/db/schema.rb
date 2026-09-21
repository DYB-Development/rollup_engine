# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_21_120000) do
  create_table "rollup_engine_datapoints", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "dimensions", default: {}, null: false
    t.string "dimensions_key", default: "", null: false
    t.string "grain", null: false
    t.string "measure", null: false
    t.datetime "period_start", null: false
    t.datetime "recomputed_at"
    t.datetime "updated_at", null: false
    t.decimal "value", null: false
    t.index ["measure", "grain", "period_start", "dimensions_key"], name: "index_rollup_engine_datapoints_unique", unique: true
  end
end
