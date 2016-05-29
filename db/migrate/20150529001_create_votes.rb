class CreateVotes < ActiveRecord::Migration
  def change
    create_table :votes do |t|
      t.string :uuid, null: false
      t.integer :left, null: false
      t.integer :right, null: false
      t.integer :result
    end
  end
end

