class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game_room, null: false, foreign_key: true
      t.text :hand, null: false, default: '[]'
      t.integer :position, null: false

      t.timestamps
    end
    
    add_index :players, [:user_id, :game_room_id], unique: true
    add_index :players, [:game_room_id, :position], unique: true
  end
end
