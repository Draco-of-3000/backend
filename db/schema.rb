# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_31_101801) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "cards", force: :cascade do |t|
    t.string "color", null: false
    t.string "value", null: false
    t.string "card_type", default: "number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["color", "value", "card_type"], name: "index_cards_on_color_and_value_and_card_type", unique: true
  end

  create_table "game_rooms", force: :cascade do |t|
    t.string "status", default: "waiting", null: false
    t.integer "turn_player_id"
    t.string "direction", default: "clockwise", null: false
    t.string "current_color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_game_rooms_on_status"
    t.index ["turn_player_id"], name: "index_game_rooms_on_turn_player_id"
  end

  create_table "game_states", force: :cascade do |t|
    t.bigint "game_room_id", null: false
    t.text "discard_pile", default: "[]", null: false
    t.text "draw_pile", default: "[]", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_room_id"], name: "index_game_states_on_game_room_id", unique: true
  end

  create_table "players", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "game_room_id", null: false
    t.text "hand", default: "[]", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_room_id", "position"], name: "index_players_on_game_room_id_and_position", unique: true
    t.index ["game_room_id"], name: "index_players_on_game_room_id"
    t.index ["user_id", "game_room_id"], name: "index_players_on_user_id_and_game_room_id", unique: true
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", limit: 50, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "game_states", "game_rooms"
  add_foreign_key "players", "game_rooms"
  add_foreign_key "players", "users"
end
