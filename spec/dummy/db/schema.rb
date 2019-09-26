# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_08_31_235615) do

  create_table "ledgerizer_accounts", force: :cascade do |t|
    t.string "tenant_type"
    t.integer "tenant_id"
    t.string "accountable_type"
    t.integer "accountable_id"
    t.string "name"
    t.string "currency"
    t.string "account_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accountable_type", "accountable_id"], name: "index_ledgerizer_accounts_on_acc_type_and_acc_id"
    t.index ["tenant_type", "tenant_id"], name: "index_ledgerizer_accounts_on_tenant_type_and_tenant_id"
  end

  create_table "ledgerizer_entries", force: :cascade do |t|
    t.string "tenant_type"
    t.integer "tenant_id"
    t.string "code"
    t.string "document_type"
    t.integer "document_id"
    t.date "entry_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_type", "document_id"], name: "index_ledgerizer_entries_on_document_type_and_document_id"
    t.index ["tenant_type", "tenant_id"], name: "index_ledgerizer_entries_on_tenant_type_and_tenant_id"
  end

  create_table "ledgerizer_lines", force: :cascade do |t|
    t.string "tenant_type"
    t.integer "tenant_id"
    t.integer "entry_id"
    t.date "entry_date"
    t.string "entry_code"
    t.string "document_type"
    t.integer "document_id"
    t.integer "account_id"
    t.string "accountable_type"
    t.integer "accountable_id"
    t.string "account_name"
    t.bigint "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "CLP", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ledgerizer_lines_on_account_id"
    t.index ["accountable_type", "accountable_id"], name: "index_ledgerizer_lines_on_accountable_type_and_accountable_id"
    t.index ["document_type", "document_id"], name: "index_ledgerizer_lines_on_document_type_and_document_id"
    t.index ["entry_id"], name: "index_ledgerizer_lines_on_entry_id"
    t.index ["tenant_type", "tenant_id"], name: "index_ledgerizer_lines_on_tenant_type_and_tenant_id"
  end

  create_table "portfolios", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
