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

ActiveRecord::Schema[8.1].define(version: 2025_12_04_065450) do
  create_table "appointments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.datetime "end_time"
    t.datetime "start_time"
    t.datetime "updated_at", null: false
    t.integer "worker_id", null: false
    t.index ["customer_id"], name: "index_appointments_on_customer_id"
    t.index ["worker_id"], name: "index_appointments_on_worker_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "receiver_id", null: false
    t.integer "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["receiver_id"], name: "index_messages_on_receiver_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "rating"
    t.integer "reviewee_id", null: false
    t.integer "reviewer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["reviewee_id"], name: "index_reviews_on_reviewee_id"
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active"
    t.string "city"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.integer "role"
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "username"
  end

  add_foreign_key "appointments", "users", column: "customer_id"
  add_foreign_key "appointments", "users", column: "worker_id"
  add_foreign_key "messages", "users", column: "receiver_id"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "reviews", "users", column: "reviewee_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
end
