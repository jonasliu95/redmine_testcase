class CreateTestcases < ActiveRecord::Migration[5.2]
  def change
    create_table :testcases do |t|
      t.integer :issue_id, null: false
      t.string :test_case_id, null: false, limit: 50
      t.string :title, null: false
      t.text :preconditions
      t.text :steps
      t.text :expected_result
      t.text :actual_result
      t.string :status, null: false, default: 'not_executed'
      t.text :comments
      t.integer :position, default: 0
      t.timestamps
    end

    add_index :testcases, [:issue_id, :test_case_id], unique: true
    add_index :testcases, :issue_id
    add_index :testcases, :position
  end
end
