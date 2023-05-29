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

ActiveRecord::Schema[7.0].define(version: 2023_05_29_143225) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "automation_rules", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "name", null: false
    t.string "trigger_event", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_automation_rules_on_tenant_id"
  end

  create_table "boxes", force: :cascade do |t|
    t.string "name", null: false
    t.string "uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id", null: false
    t.index ["tenant_id"], name: "index_boxes_on_tenant_id"
  end

  create_table "drafts", force: :cascade do |t|
    t.bigint "import_id"
    t.integer "status", default: 0
    t.string "recipient_uri"
    t.string "posp_id"
    t.string "posp_version"
    t.string "message_type"
    t.string "message_subject"
    t.string "import_subfolder"
    t.string "sender_business_reference"
    t.string "recipient_business_reference"
    t.uuid "message_id"
    t.uuid "correlation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "box_id", null: false
    t.index ["box_id"], name: "index_drafts_on_box_id"
    t.index ["import_id"], name: "index_drafts_on_import_id"
  end

  create_table "drafts_imports", force: :cascade do |t|
    t.string "name", null: false
    t.integer "status", default: 0
    t.string "content_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "box_id", null: false
    t.index ["box_id"], name: "index_drafts_imports_on_box_id"
  end

  create_table "drafts_objects", force: :cascade do |t|
    t.bigint "draft_id", null: false
    t.uuid "uuid", null: false
    t.string "name", null: false
    t.boolean "signed"
    t.boolean "to_be_signed"
    t.boolean "form"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draft_id"], name: "index_drafts_objects_on_draft_id"
  end

  create_table "folders", force: :cascade do |t|
    t.bigint "box_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["box_id"], name: "index_folders_on_box_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "govbox_api_connections", force: :cascade do |t|
    t.bigint "box_id"
    t.string "sub", null: false
    t.uuid "obo"
    t.string "api_token_private_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["box_id"], name: "index_govbox_api_connections_on_box_id"
  end

  create_table "govbox_messages", force: :cascade do |t|
    t.uuid "message_id", null: false
    t.uuid "correlation_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "message_object_data", force: :cascade do |t|
    t.bigint "message_object_id", null: false
    t.text "blob", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_object_id"], name: "index_message_object_data_on_message_object_id"
  end

  create_table "message_objects", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.string "name", null: false
    t.string "mimetype", null: false
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_message_objects_on_message_id"
  end

  create_table "message_threads", force: :cascade do |t|
    t.bigint "folder_id", null: false
    t.string "title", null: false
    t.string "original_title", null: false
    t.uuid "merge_uuids", default: [], null: false, array: true
    t.datetime "delivered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["folder_id"], name: "index_message_threads_on_folder_id"
  end

  create_table "messages", force: :cascade do |t|
    t.uuid "uuid", null: false
    t.bigint "message_thread_id", null: false
    t.string "title", null: false
    t.string "sender_name", null: false
    t.string "recipient_name", null: false
    t.datetime "delivered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_thread_id"], name: "index_messages_on_message_thread_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.bigint "tenant_id"
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "automation_rules", "tenants"
  add_foreign_key "boxes", "tenants"
  add_foreign_key "drafts", "boxes"
  add_foreign_key "drafts", "drafts_imports", column: "import_id"
  add_foreign_key "drafts_imports", "boxes"
  add_foreign_key "drafts_objects", "drafts"
  add_foreign_key "folders", "boxes"
  add_foreign_key "govbox_api_connections", "boxes"
  add_foreign_key "message_object_data", "message_objects"
  add_foreign_key "message_objects", "messages"
  add_foreign_key "message_threads", "folders"
  add_foreign_key "messages", "message_threads"
  add_foreign_key "users", "tenants"
end
