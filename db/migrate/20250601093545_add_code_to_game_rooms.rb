class AddCodeToGameRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :game_rooms, :code, :string
    add_index :game_rooms, :code, unique: true
  end
end
