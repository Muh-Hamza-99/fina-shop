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

ActiveRecord::Schema[8.1].define(version: 2026_11_27_150201) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "name_ar", null: false
    t.string "name_en"
    t.text "description_ar"
    t.text "description_en"
    t.string "subdomain", null: false
    t.string "custom_domain"
    t.string "email"
    t.string "phone"
    t.string "whatsapp_phone"
    t.string "website"
    t.string "country_code", default: "SA", null: false
    t.string "region"
    t.string "city"
    t.string "district"
    t.string "street"
    t.string "building_number"
    t.string "postal_code"
    t.string "unified_number_700"
    t.string "cr_number"
    t.string "vat_number"
    t.boolean "zatca_enabled", default: false, null: false
    t.boolean "show_prices_default", default: true, null: false
    t.boolean "show_stock_default", default: false, null: false
    t.boolean "pos_sync_enabled", default: false, null: false
    t.string "fina_merchant_id"
    t.string "subscription_status", default: "trialing", null: false
    t.datetime "trial_ends_at"
    t.jsonb "theme_config", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_domain"], name: "index_stores_on_custom_domain", unique: true
    t.index ["subdomain"], name: "index_stores_on_subdomain", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "name", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "role", default: "staff", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["store_id"], name: "index_users_on_store_id"
  end

  add_foreign_key "sessions", "users"
  add_foreign_key "users", "stores"
end
