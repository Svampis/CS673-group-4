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

ActiveRecord::Schema[8.1].define(version: 2025_12_05_060312) do
  create_table "admins", force: :cascade do |t|
    t.string "city"
    t.datetime "created_at", null: false
    t.string "fname"
    t.string "lname"
    t.string "number"
    t.string "state"
    t.string "street"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_admins_on_user_id", unique: true
  end

  create_table "appointments", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.integer "homeowner_id", null: false
    t.text "job_description"
    t.integer "project_id"
    t.datetime "rejected_at"
    t.text "rejection_reason"
    t.datetime "scheduled_end"
    t.datetime "scheduled_start"
    t.string "status", default: "pending"
    t.integer "tradesman_id", null: false
    t.datetime "updated_at", null: false
    t.index ["homeowner_id"], name: "index_appointments_on_homeowner_id"
    t.index ["project_id"], name: "index_appointments_on_project_id"
    t.index ["scheduled_start"], name: "index_appointments_on_scheduled_start"
    t.index ["status"], name: "index_appointments_on_status"
    t.index ["tradesman_id"], name: "index_appointments_on_tradesman_id"
  end

  create_table "bids", force: :cascade do |t|
    t.decimal "amount"
    t.integer "appointment_id"
    t.decimal "bidding_increment"
    t.datetime "created_at", null: false
    t.decimal "hourly_rate"
    t.integer "project_id", null: false
    t.string "status", default: "pending"
    t.integer "tradesman_id", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_bids_on_appointment_id"
    t.index ["project_id"], name: "index_bids_on_project_id"
    t.index ["status"], name: "index_bids_on_status"
    t.index ["tradesman_id"], name: "index_bids_on_tradesman_id"
  end

  create_table "contractors", force: :cascade do |t|
    t.string "city"
    t.datetime "created_at", null: false
    t.string "fname"
    t.decimal "latitude", precision: 10, scale: 8
    t.string "lname"
    t.decimal "longitude", precision: 11, scale: 8
    t.string "number"
    t.string "state"
    t.string "street"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_contractors_on_user_id", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "participant1_id", null: false
    t.integer "participant2_id", null: false
    t.datetime "updated_at", null: false
    t.index ["participant1_id", "participant2_id"], name: "index_conversations_on_participant1_id_and_participant2_id"
    t.index ["participant1_id"], name: "index_conversations_on_participant1_id"
    t.index ["participant2_id"], name: "index_conversations_on_participant2_id"
  end

  create_table "estimates", force: :cascade do |t|
    t.decimal "amount"
    t.integer "appointment_id"
    t.datetime "created_at", null: false
    t.integer "homeowner_id", null: false
    t.text "notes"
    t.integer "project_id"
    t.string "status", default: "pending"
    t.integer "tradesman_id", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 1
    t.index ["appointment_id"], name: "index_estimates_on_appointment_id"
    t.index ["homeowner_id"], name: "index_estimates_on_homeowner_id"
    t.index ["project_id"], name: "index_estimates_on_project_id"
    t.index ["status"], name: "index_estimates_on_status"
    t.index ["tradesman_id"], name: "index_estimates_on_tradesman_id"
  end

  create_table "homeowners", force: :cascade do |t|
    t.string "city"
    t.datetime "created_at", null: false
    t.string "fname"
    t.decimal "latitude", precision: 10, scale: 8
    t.string "lname"
    t.decimal "longitude", precision: 11, scale: 8
    t.string "number"
    t.string "state"
    t.string "street"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_homeowners_on_user_id", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.string "attachment"
    t.text "content"
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "read_at"
    t.integer "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "message"
    t.string "notification_type"
    t.boolean "read", default: false
    t.datetime "read_at"
    t.integer "related_id"
    t.string "related_type"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["read"], name: "index_notifications_on_read"
    t.index ["related_id"], name: "index_notifications_on_related_id"
    t.index ["related_type"], name: "index_notifications_on_related_type"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.integer "assigned_id"
    t.decimal "bidding_increments"
    t.decimal "budget"
    t.integer "contractor_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "homeowner_id"
    t.decimal "latitude", precision: 10, scale: 8
    t.text "location"
    t.decimal "longitude", precision: 11, scale: 8
    t.date "preferred_date"
    t.text "requirements"
    t.string "status", default: "open"
    t.string "timespan"
    t.string "title"
    t.string "trade_type"
    t.datetime "updated_at", null: false
    t.index ["assigned_id"], name: "index_projects_on_assigned_id"
    t.index ["contractor_id"], name: "index_projects_on_contractor_id"
    t.index ["homeowner_id"], name: "index_projects_on_homeowner_id"
    t.index ["status"], name: "index_projects_on_status"
    t.index ["trade_type"], name: "index_projects_on_trade_type"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "appointment_id"
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "homeowner_id", null: false
    t.integer "rating"
    t.integer "tradesman_id", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_reviews_on_appointment_id"
    t.index ["homeowner_id"], name: "index_reviews_on_homeowner_id"
    t.index ["tradesman_id"], name: "index_reviews_on_tradesman_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.time "end_time"
    t.time "start_time"
    t.string "status", default: "available"
    t.integer "tradesman_id", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_schedules_on_date"
    t.index ["tradesman_id", "date"], name: "index_schedules_on_tradesman_id_and_date"
    t.index ["tradesman_id"], name: "index_schedules_on_tradesman_id"
  end

  create_table "tradesman_verifications", force: :cascade do |t|
    t.integer "admin_id"
    t.text "certification_documents"
    t.datetime "created_at", null: false
    t.text "identification_documents"
    t.string "license_number"
    t.text "rejection_reason"
    t.datetime "reviewed_at"
    t.string "status", default: "pending"
    t.integer "tradesman_id", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_tradesman_verifications_on_admin_id"
    t.index ["status"], name: "index_tradesman_verifications_on_status"
    t.index ["tradesman_id"], name: "index_tradesman_verifications_on_tradesman_id"
  end

  create_table "tradesmen", force: :cascade do |t|
    t.string "business_name"
    t.text "certification_documents"
    t.string "city"
    t.datetime "created_at", null: false
    t.string "description"
    t.string "fname"
    t.decimal "hourly_rate"
    t.decimal "latitude", precision: 10, scale: 8
    t.string "license_number"
    t.string "lname"
    t.decimal "longitude", precision: 11, scale: 8
    t.string "number"
    t.text "photos"
    t.decimal "service_radius"
    t.string "state"
    t.string "street"
    t.string "trade_specialty"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "verification_status", default: "pending"
    t.integer "years_of_experience"
    t.index ["trade_specialty"], name: "index_tradesmen_on_trade_specialty"
    t.index ["user_id"], name: "index_tradesmen_on_user_id", unique: true
    t.index ["verification_status"], name: "index_tradesmen_on_verification_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_hash", null: false
    t.string "role", null: false
    t.string "status", default: "activated"
    t.boolean "two_factor_enabled", default: false
    t.string "two_factor_secret"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "admins", "users"
  add_foreign_key "appointments", "homeowners"
  add_foreign_key "appointments", "projects"
  add_foreign_key "appointments", "tradesmen"
  add_foreign_key "bids", "appointments"
  add_foreign_key "bids", "projects"
  add_foreign_key "bids", "tradesmen"
  add_foreign_key "contractors", "users"
  add_foreign_key "conversations", "users", column: "participant1_id"
  add_foreign_key "conversations", "users", column: "participant2_id"
  add_foreign_key "estimates", "appointments"
  add_foreign_key "estimates", "homeowners"
  add_foreign_key "estimates", "projects"
  add_foreign_key "estimates", "tradesmen"
  add_foreign_key "homeowners", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "projects", "homeowners"
  add_foreign_key "projects", "tradesmen", column: "assigned_id"
  add_foreign_key "projects", "users", column: "contractor_id"
  add_foreign_key "reviews", "appointments"
  add_foreign_key "reviews", "homeowners"
  add_foreign_key "reviews", "tradesmen"
  add_foreign_key "schedules", "tradesmen"
  add_foreign_key "tradesman_verifications", "tradesmen"
  add_foreign_key "tradesman_verifications", "users", column: "admin_id"
  add_foreign_key "tradesmen", "users"
end
