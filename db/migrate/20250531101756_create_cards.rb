class CreateCards < ActiveRecord::Migration[8.0]
  def change
    create_table :cards do |t|
      t.string :color, null: false
      t.string :value, null: false
      t.string :card_type, null: false, default: 'number'

      t.timestamps
    end
    
    add_index :cards, [:color, :value, :card_type], unique: true
  end
end
