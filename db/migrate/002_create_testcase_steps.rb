class CreateTestcaseSteps < ActiveRecord::Migration[5.2]
  def change
    create_table :testcase_steps do |t|
      t.references :testcase, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.text :action
      t.text :test_data
      t.text :expected_result
      t.text :actual_result
      t.string :status, null: false, default: 'not_executed'
      t.timestamps
    end

    add_index :testcase_steps, [:testcase_id, :position]
  end
end
