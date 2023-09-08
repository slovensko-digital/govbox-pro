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

ActiveRecord::Schema[7.0].define(version: 2023_08_18_084605) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "group_type", ["ALL", "USER", "CUSTOM", "ADMIN"]

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

  create_table "automation_actions", force: :cascade do |t|
    t.string "type"
    t.bigint "automation_rule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["automation_rule_id"], name: "index_automation_actions_on_automation_rule_id"
  end

  create_table "automation_conditions", force: :cascade do |t|
    t.string "attr"
    t.string "type"
    t.string "value"
    t.bigint "automation_rule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["automation_rule_id"], name: "index_automation_conditions_on_automation_rule_id"
  end

  create_table "automation_rules", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "name", null: false
    t.string "trigger_event", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["tenant_id"], name: "index_automation_rules_on_tenant_id"
    t.index ["user_id"], name: "index_automation_rules_on_user_id"
  end

  create_table "boxes", force: :cascade do |t|
    t.string "name", null: false
    t.string "uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id", null: false
    t.boolean "syncable", default: true, null: false
    t.index ["tenant_id"], name: "index_boxes_on_tenant_id"
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

  create_table "govbox_folders", force: :cascade do |t|
    t.integer "edesk_folder_id", null: false
    t.string "name", null: false
    t.boolean "system", null: false
    t.bigint "parent_folder_id"
    t.bigint "box_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["box_id"], name: "index_govbox_folders_on_box_id"
    t.index ["edesk_folder_id"], name: "index_govbox_folders_on_edesk_folder_id", unique: true
    t.index ["parent_folder_id"], name: "index_govbox_folders_on_parent_folder_id"
  end

  create_table "govbox_messages", force: :cascade do |t|
    t.uuid "message_id", null: false
    t.uuid "correlation_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "edesk_message_id", null: false
    t.datetime "delivered_at", null: false
    t.string "edesk_class", null: false
    t.bigint "folder_id", null: false
    t.json "payload", null: false
    t.index ["folder_id"], name: "index_govbox_messages_on_folder_id"
  end

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "tenant_id", null: false
    t.enum "group_type", null: false, enum_type: "group_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_groups_on_tenant_id"
  end

  create_table "message_drafts_imports", force: :cascade do |t|
    t.string "name", null: false
    t.integer "status", default: 0
    t.string "content_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "box_id", null: false
    t.index ["box_id"], name: "index_message_drafts_imports_on_box_id"
  end

  create_table "message_object_data", force: :cascade do |t|
    t.bigint "message_object_id", null: false
    t.binary "blob", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_object_id"], name: "index_message_object_data_on_message_object_id"
  end

  create_table "message_objects", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.string "name"
    t.string "mimetype", null: false
    t.string "object_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_signed"
    t.boolean "to_be_signed", default: false, null: false
    t.index ["message_id"], name: "index_message_objects_on_message_id"
  end

  create_table "message_thread_merge_identifiers", force: :cascade do |t|
    t.bigint "message_thread_id", null: false
    t.uuid "uuid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_thread_id"], name: "index_message_thread_merge_identifiers_on_message_thread_id"
    t.index ["uuid"], name: "index_message_thread_merge_identifiers_on_uuid", unique: true
  end

  create_table "message_threads", force: :cascade do |t|
    t.bigint "folder_id", null: false
    t.string "title", null: false
    t.string "original_title", null: false
    t.datetime "delivered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_message_delivered_at", precision: nil, null: false
    t.index ["folder_id"], name: "index_message_threads_on_folder_id"
  end

  create_table "message_threads_tags", force: :cascade do |t|
    t.bigint "message_thread_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_thread_id", "tag_id"], name: "index_message_threads_tags_on_message_thread_id_and_tag_id"
    t.index ["message_thread_id"], name: "index_message_threads_tags_on_message_thread_id"
    t.index ["tag_id", "message_thread_id"], name: "index_message_threads_tags_on_tag_id_and_message_thread_id", unique: true
    t.index ["tag_id"], name: "index_message_threads_tags_on_tag_id"
  end

  create_table "messages", force: :cascade do |t|
    t.uuid "uuid", null: false
    t.bigint "message_thread_id", null: false
    t.string "title"
    t.string "sender_name"
    t.string "recipient_name"
    t.datetime "delivered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "html_visualization"
    t.boolean "read", default: false, null: false
    t.json "metadata"
    t.string "type"
    t.boolean "replyable", default: true, null: false
    t.bigint "import_id"
    t.bigint "author_id"
    t.index ["author_id"], name: "index_messages_on_author_id"
    t.index ["import_id"], name: "index_messages_on_import_id"
    t.index ["message_thread_id"], name: "index_messages_on_message_thread_id"
  end

  create_table "messages_tags", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_messages_tags_on_message_id"
    t.index ["tag_id"], name: "index_messages_tags_on_tag_id"
  end

  create_table "tag_groups", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_tag_groups_on_group_id"
    t.index ["tag_id"], name: "index_tag_groups_on_tag_id"
  end

  create_table "tag_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_tag_users_on_tag_id"
    t.index ["user_id"], name: "index_tag_users_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.bigint "user_id"
    t.index ["tenant_id"], name: "index_tags_on_tenant_id"
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "upvs_form_template_related_documents", force: :cascade do |t|
    t.bigint "upvs_form_template_id", null: false
    t.string "data", null: false
    t.string "language", null: false
    t.string "document_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["upvs_form_template_id", "language", "document_type"], name: "index_related_documents_on_template_id_and_language_and_type", unique: true
    t.index ["upvs_form_template_id"], name: "index_upvs_form_template_related_documents_on_form_template_id"
  end

  create_table "upvs_form_templates", force: :cascade do |t|
    t.string "identifier", null: false
    t.string "version", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier", "version"], name: "index_form_templates_on_identifier_and_version", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "tenant_id"
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "email"], name: "index_users_on_tenant_id_and_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "automation_actions", "automation_rules"
  add_foreign_key "automation_conditions", "automation_rules"
  add_foreign_key "automation_rules", "tenants"
  add_foreign_key "automation_rules", "users"
  add_foreign_key "boxes", "tenants"
  add_foreign_key "folders", "boxes"
  add_foreign_key "govbox_api_connections", "boxes"
  add_foreign_key "govbox_folders", "boxes"
  add_foreign_key "govbox_folders", "govbox_folders", column: "parent_folder_id"
  add_foreign_key "govbox_messages", "govbox_folders", column: "folder_id"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "groups", "tenants"
  add_foreign_key "message_drafts_imports", "boxes"
  add_foreign_key "message_object_data", "message_objects"
  add_foreign_key "message_objects", "messages"
  add_foreign_key "message_thread_merge_identifiers", "message_threads"
  add_foreign_key "message_threads", "folders"
  add_foreign_key "message_threads_tags", "message_threads"
  add_foreign_key "message_threads_tags", "tags"
  add_foreign_key "messages", "message_drafts_imports", column: "import_id"
  add_foreign_key "messages", "message_threads"
  add_foreign_key "messages", "users", column: "author_id"
  add_foreign_key "messages_tags", "messages"
  add_foreign_key "messages_tags", "tags"
  add_foreign_key "tag_groups", "groups"
  add_foreign_key "tag_groups", "tags"
  add_foreign_key "tag_users", "tags"
  add_foreign_key "tag_users", "users"
  add_foreign_key "tags", "tenants"
  add_foreign_key "tags", "users"
  add_foreign_key "upvs_form_template_related_documents", "upvs_form_templates"
  add_foreign_key "users", "tenants"
end
