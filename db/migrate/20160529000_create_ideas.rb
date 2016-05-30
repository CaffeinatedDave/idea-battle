class CreateIdeas < ActiveRecord::Migration
  def change
    create_table :ideas do |t|
      t.string :title
      t.string :description
      t.integer :seen, default: 0
      t.integer :chosen, default: 0
    end
  end
end

