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

ActiveRecord::Schema[8.1].define(version: 2025_11_28_080953) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "chat_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_chat_sessions_on_topic_id"
  end

  create_table "document_chunks", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.vector "embedding", limit: 768
    t.jsonb "metadata"
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_document_chunks_on_topic_id"
  end

  create_table "embedding_cache_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.vector "embedding", limit: 768
    t.string "text_hash"
    t.datetime "updated_at", null: false
    t.index ["text_hash"], name: "index_embedding_cache_entries_on_text_hash", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_session_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "role"
    t.datetime "updated_at", null: false
    t.index ["chat_session_id"], name: "index_messages_on_chat_session_id"
  end

  create_table "topics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "chat_sessions", "topics"
  add_foreign_key "document_chunks", "topics"
  add_foreign_key "messages", "chat_sessions"
end
