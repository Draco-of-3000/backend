class CreateGameRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :game_rooms do |t|
      t.string :status, null: false, default: 'waiting'
      t.integer :turn_player_id
      t.string :direction, null: false, default: 'clockwise'
      t.string :current_color

      t.timestamps
    end
    
    add_index :game_rooms, :status
    add_index :game_rooms, :turn_player_id
  end
end
