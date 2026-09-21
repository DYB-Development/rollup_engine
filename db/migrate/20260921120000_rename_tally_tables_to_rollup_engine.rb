class RenameTallyTablesToRollupEngine < ActiveRecord::Migration[8.1]
  def change
    rename_table :tally_datapoints, :rollup_engine_datapoints
    rename_index :rollup_engine_datapoints,
      "index_tally_datapoints_unique",
      "index_rollup_engine_datapoints_unique"
  end
end
