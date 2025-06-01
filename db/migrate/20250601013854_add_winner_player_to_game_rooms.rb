class AddWinnerPlayerToGameRooms < ActiveRecord::Migration[7.1]
  def change
    add_reference :game_rooms, :winner_player, null: true, foreign_key: { to_table: :players }
  end
end
