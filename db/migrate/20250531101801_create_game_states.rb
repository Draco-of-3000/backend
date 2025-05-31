class CreateGameStates < ActiveRecord::Migration[8.0]
  def change
    create_table :game_states do |t|
      t.references :game_room, null: false, foreign_key: true, index: { unique: true }
      t.text :discard_pile, null: false, default: '[]'
      t.text :draw_pile, null: false, default: '[]'

      t.timestamps
    end
  end
end
