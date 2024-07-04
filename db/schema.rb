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

ActiveRecord::Schema[7.1].define(version: 2024_07_03_231723) do
  create_table "games", force: :cascade do |t|
    t.integer "boards_tall", null: false
    t.integer "boards_wide", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_turn", default: 0, null: false
    t.integer "minimum_turn_duration", default: 10, null: false
    t.boolean "processing_moves", default: false, null: false
    t.datetime "last_turn_completed_at", null: false
    t.integer "stop_processing_moves_at"
  end

  create_table "moves", force: :cascade do |t|
    t.integer "target_square", null: false
    t.integer "piece_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "turn", null: false
    t.string "direction", null: false
    t.string "pending_spawn_kind"
    t.index ["piece_id"], name: "index_moves_on_piece_id"
  end

  create_table "pieces", force: :cascade do |t|
    t.integer "player_id", null: false
    t.string "kind", null: false
    t.integer "square", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_pieces_on_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.boolean "is_black", null: false
    t.integer "game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "points", default: 0, null: false
    t.integer "score", default: 0, null: false
    t.index ["game_id"], name: "index_players_on_game_id"
  end

end
