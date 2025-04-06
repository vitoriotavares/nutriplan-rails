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

ActiveRecord::Schema[8.0].define(version: 2025_04_05_235720) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "anamneses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "health_data"
    t.jsonb "dietary_preferences"
    t.jsonb "restrictions"
    t.jsonb "lifestyle"
    t.jsonb "goals"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "client_name"
    t.index ["user_id"], name: "index_anamneses_on_user_id"
  end

  create_table "food_items", force: :cascade do |t|
    t.bigint "meal_id", null: false
    t.string "name"
    t.float "quantity"
    t.string "unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "substitutes"
    t.index ["meal_id"], name: "index_food_items_on_meal_id"
  end

  create_table "food_plans", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.text "description"
    t.date "start_date"
    t.date "end_date"
    t.integer "calories"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "anamnesis_id"
    t.text "ai_response"
    t.index ["anamnesis_id"], name: "index_food_plans_on_anamnesis_id"
    t.index ["user_id"], name: "index_food_plans_on_user_id"
  end

  create_table "meals", force: :cascade do |t|
    t.bigint "food_plan_id", null: false
    t.string "name"
    t.string "time"
    t.string "objective"
    t.integer "meal_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["food_plan_id"], name: "index_meals_on_food_plan_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 8, scale: 2, null: false
    t.integer "food_plans_limit", default: 1
    t.boolean "full_recipe_access", default: false
    t.boolean "priority_support", default: false
    t.string "mercado_pago_id"
    t.boolean "active", default: true
    t.boolean "is_default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_plans_on_name", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.date "date_of_birth"
    t.string "gender"
    t.float "height"
    t.float "weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "name"
    t.integer "preparation_time"
    t.integer "cooking_time"
    t.jsonb "instructions"
    t.jsonb "nutritional_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plan_id", null: false
    t.string "mercado_pago_subscription_id"
    t.string "status", default: "pending"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "canceled_at"
    t.boolean "active", default: false
    t.boolean "auto_renew", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mercado_pago_subscription_id"], name: "index_subscriptions_on_mercado_pago_subscription_id", unique: true
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["user_id", "active"], name: "index_subscriptions_on_user_id_and_active"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "subscription_id", null: false
    t.string "mercado_pago_transaction_id"
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.string "status", default: "pending"
    t.string "payment_method"
    t.text "description"
    t.string "currency", default: "BRL"
    t.jsonb "payment_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "transaction_type"
    t.index ["mercado_pago_transaction_id"], name: "index_transactions_on_mercado_pago_transaction_id", unique: true
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["subscription_id"], name: "index_transactions_on_subscription_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "additional_food_plans", default: 0, null: false
  end

  create_table "water_plans", force: :cascade do |t|
    t.bigint "food_plan_id", null: false
    t.float "daily_amount"
    t.text "recommendation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["food_plan_id"], name: "index_water_plans_on_food_plan_id"
  end

  add_foreign_key "anamneses", "users"
  add_foreign_key "food_items", "meals"
  add_foreign_key "food_plans", "anamneses"
  add_foreign_key "food_plans", "users"
  add_foreign_key "meals", "food_plans"
  add_foreign_key "profiles", "users"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "transactions", "subscriptions"
  add_foreign_key "transactions", "users"
  add_foreign_key "water_plans", "food_plans"
end
