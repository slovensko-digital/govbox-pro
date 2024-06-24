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

ActiveRecord::Schema[7.1].define(version: 2024_06_24_114024) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "color", ["slate", "gray", "zinc", "neutral", "stone", "red", "orange", "amber", "yellow", "lime", "green", "emerald", "teal", "cyan", "sky", "blue", "indigo", "violet", "purple", "fuchsia", "pink", "rose"]
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

  create_table "api_connections", force: :cascade do |t|
    t.string "sub", null: false
    t.uuid "obo"
    t.string "api_token_private_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.bigint "tenant_id"
    t.index ["tenant_id"], name: "index_api_connections_on_tenant_id"
  end

  create_table "api_requests", force: :cascade do |t|
    t.string "endpoint_path", null: false
    t.string "endpoint_method", null: false
    t.integer "response_status", null: false
    t.string "authenticity_token", null: false
    t.inet "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_api_requests_on_created_at"
    t.index ["endpoint_path", "created_at"], name: "index_api_requests_on_endpoint_path_and_created_at"
    t.index ["ip_address", "created_at"], name: "index_api_requests_on_ip_address_and_created_at"
  end

  create_table "archived_object_versions", force: :cascade do |t|
    t.bigint "archived_object_id", null: false
    t.binary "content", null: false
    t.string "validation_result"
    t.datetime "valid_to", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["archived_object_id"], name: "index_archived_object_versions_on_archived_object_id"
  end

  create_table "archived_objects", force: :cascade do |t|
    t.bigint "message_object_id", null: false
    t.string "validation_result", null: false
    t.string "signature_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_object_id"], name: "index_archived_objects_on_message_object_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "type", null: false
    t.bigint "tenant_id"
    t.datetime "happened_at", precision: nil, null: false
    t.string "actor_name"
    t.bigint "actor_id"
    t.string "previous_value"
    t.string "new_value"
    t.jsonb "changeset"
    t.bigint "message_thread_id"
    t.integer "thread_id_archived"
    t.string "thread_title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_audit_logs_on_actor_id"
    t.index ["message_thread_id"], name: "index_audit_logs_on_message_thread_id"
    t.index ["tenant_id", "actor_id", "happened_at"], name: "index_audit_logs_on_tenant_id_and_actor_id_and_happened_at"
    t.index ["tenant_id", "message_thread_id", "happened_at"], name: "index_audit_logs_on_tenant_id_thread_id_happened_at"
    t.index ["tenant_id"], name: "index_audit_logs_on_tenant_id"
  end

  create_table "automation_actions", force: :cascade do |t|
    t.string "type"
    t.bigint "automation_rule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.string "action_object_type"
    t.bigint "action_object_id"
    t.index ["action_object_type", "action_object_id"], name: "index_automation_actions_on_action_object"
    t.index ["automation_rule_id"], name: "index_automation_actions_on_automation_rule_id"
  end

  create_table "automation_conditions", force: :cascade do |t|
    t.string "attr"
    t.string "type"
    t.string "value"
    t.bigint "automation_rule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "condition_object_type"
    t.bigint "condition_object_id"
    t.index ["automation_rule_id"], name: "index_automation_conditions_on_automation_rule_id"
    t.index ["condition_object_type", "condition_object_id"], name: "index_automation_conditions_on_condition_object"
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
    t.string "short_name"
    t.enum "color", enum_type: "color"
    t.bigint "api_connection_id"
    t.jsonb "settings"
    t.index "tenant_id, api_connection_id, ((settings ->> 'obo'::text))", name: "api_connection_box_settings_obo", unique: true
    t.index ["api_connection_id"], name: "index_boxes_on_api_connection_id"
    t.index ["tenant_id", "short_name"], name: "index_boxes_on_tenant_id_and_short_name", unique: true
    t.index ["tenant_id"], name: "index_boxes_on_tenant_id"
  end

  create_table "filter_subscriptions", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "user_id", null: false
    t.bigint "filter_id", null: false
    t.datetime "last_notify_run_at"
    t.string "events", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["filter_id"], name: "index_filter_subscriptions_on_filter_id"
    t.index ["tenant_id"], name: "index_filter_subscriptions_on_tenant_id"
    t.index ["user_id"], name: "index_filter_subscriptions_on_user_id"
  end

  create_table "filters", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "author_id", null: false
    t.string "name", null: false
    t.string "query"
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", null: false
    t.bigint "tag_id"
    t.boolean "is_pinned", default: false, null: false
    t.index ["author_id"], name: "index_filters_on_author_id"
    t.index ["is_pinned"], name: "index_filters_on_is_pinned"
    t.index ["tag_id"], name: "index_filters_on_tag_id"
    t.index ["tenant_id"], name: "index_filters_on_tenant_id"
    t.index ["type"], name: "index_filters_on_type"
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
    t.integer "error_event", limit: 2
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
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
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
    t.index ["edesk_folder_id", "box_id"], name: "index_govbox_folders_on_edesk_folder_id_and_box_id", unique: true
    t.index ["parent_folder_id"], name: "index_govbox_folders_on_parent_folder_id"
  end

  create_table "govbox_messages", force: :cascade do |t|
    t.uuid "message_id", null: false
    t.uuid "correlation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "edesk_message_id", null: false
    t.datetime "delivered_at", null: false
    t.string "edesk_class", null: false
    t.bigint "folder_id", null: false
    t.json "payload", null: false
    t.index "((((payload -> 'delivery_notification'::text) -> 'consignment'::text) ->> 'message_id'::text))", name: "index_govbox_messages_on_delivery_notification_id", using: :hash
    t.index ["edesk_message_id", "folder_id"], name: "index_govbox_messages_on_edesk_message_id_and_folder_id", unique: true
    t.index ["folder_id"], name: "index_govbox_messages_on_folder_id"
  end

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "user_id"], name: "index_group_memberships_on_group_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "tenant_id", null: false
    t.enum "group_type", enum_type: "group_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", null: false
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
    t.string "mimetype"
    t.string "object_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_signed"
    t.boolean "to_be_signed", default: false, null: false
    t.boolean "visualizable"
    t.index ["message_id"], name: "index_message_objects_on_message_id"
  end

  create_table "message_objects_tags", force: :cascade do |t|
    t.bigint "message_object_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_object_id", "tag_id"], name: "index_message_objects_tags_on_message_object_id_and_tag_id", unique: true
    t.index ["message_object_id"], name: "index_message_objects_tags_on_message_object_id"
    t.index ["tag_id"], name: "index_message_objects_tags_on_tag_id"
  end

  create_table "message_relations", force: :cascade do |t|
    t.bigint "message_id"
    t.bigint "related_message_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_message_relations_on_message_id"
    t.index ["related_message_id"], name: "index_message_relations_on_related_message_id"
  end

  create_table "message_templates", force: :cascade do |t|
    t.bigint "tenant_id"
    t.string "name", null: false
    t.text "content", null: false
    t.string "type"
    t.jsonb "metadata", default: {}
    t.boolean "system", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_message_templates_on_tenant_id"
  end

  create_table "message_thread_merge_identifiers", force: :cascade do |t|
    t.bigint "message_thread_id", null: false
    t.uuid "uuid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "box_id", null: false
    t.index ["box_id"], name: "index_message_thread_merge_identifiers_on_box_id"
    t.index ["message_thread_id"], name: "index_message_thread_merge_identifiers_on_message_thread_id"
    t.index ["uuid", "box_id"], name: "index_message_thread_merge_identifiers_on_uuid_and_box_id", unique: true
  end

  create_table "message_thread_notes", force: :cascade do |t|
    t.bigint "message_thread_id", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_thread_id"], name: "index_message_thread_notes_on_message_thread_id"
  end

  create_table "message_threads", force: :cascade do |t|
    t.bigint "folder_id"
    t.string "title", null: false
    t.string "original_title", null: false
    t.datetime "delivered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_message_delivered_at", null: false
    t.bigint "box_id", null: false
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
    t.json "metadata", default: {}
    t.string "type"
    t.boolean "replyable", default: true, null: false
    t.bigint "import_id"
    t.bigint "author_id"
    t.boolean "collapsed", default: false, null: false
    t.boolean "outbox", default: false, null: false
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

  create_table "nested_message_objects", force: :cascade do |t|
    t.string "name"
    t.string "mimetype"
    t.binary "content", null: false
    t.bigint "message_object_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_object_id"], name: "index_nested_message_objects_on_message_object_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "type", null: false
    t.bigint "user_id", null: false
    t.bigint "message_thread_id", null: false
    t.bigint "message_id"
    t.bigint "filter_subscription_id"
    t.string "filter_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["filter_subscription_id"], name: "index_notifications_on_filter_subscription_id"
    t.index ["message_id"], name: "index_notifications_on_message_id"
    t.index ["message_thread_id"], name: "index_notifications_on_message_thread_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "searchable_message_threads", force: :cascade do |t|
    t.integer "message_thread_id", null: false
    t.text "title", null: false
    t.text "content", null: false
    t.text "tag_names", null: false
    t.integer "tag_ids", default: [], null: false, array: true
    t.datetime "last_message_delivered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id", null: false
    t.integer "box_id", null: false
    t.string "note", null: false
    t.index "((((to_tsvector('simple'::regconfig, COALESCE(title, ''::text)) || to_tsvector('simple'::regconfig, COALESCE(content, ''::text))) || to_tsvector('simple'::regconfig, COALESCE((note)::text, ''::text))) || to_tsvector('simple'::regconfig, COALESCE(tag_names, ''::text))))", name: "idx_searchable_message_threads_fulltext", using: :gin
    t.index ["id", "box_id", "last_message_delivered_at"], name: "idx_on_id_box_id_last_message_delivered_at_5a4090c55e", unique: true
    t.index ["message_thread_id"], name: "index_searchable_message_threads_on_message_thread_id", unique: true
  end

  create_table "stats_message_submission_requests", force: :cascade do |t|
    t.bigint "box_id", null: false
    t.string "request_url"
    t.integer "response_status"
    t.boolean "bulk"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["box_id"], name: "index_stats_message_submission_requests_on_box_id"
  end

  create_table "tag_groups", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_tag_groups_on_group_id"
    t.index ["tag_id"], name: "index_tag_groups_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.bigint "owner_id"
    t.string "external_name"
    t.string "type", null: false
    t.string "icon"
    t.integer "tag_groups_count", default: 0, null: false
    t.enum "color", enum_type: "color"
    t.index "tenant_id, type, lower((name)::text)", name: "index_tags_on_tenant_id_and_type_and_lowercase_name", unique: true
    t.index ["owner_id"], name: "index_tags_on_owner_id"
    t.index ["tenant_id", "type"], name: "signings_tags", unique: true, where: "((type)::text = ANY ((ARRAY['SignatureRequestedTag'::character varying, 'SignedTag'::character varying])::text[]))"
    t.index ["tenant_id"], name: "index_tags_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "feature_flags", default: [], array: true
    t.string "api_token_public_key"
  end

  create_table "upvs_form_related_documents", force: :cascade do |t|
    t.bigint "upvs_form_id", null: false
    t.string "data", null: false
    t.string "language", null: false
    t.string "document_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["upvs_form_id", "language", "document_type"], name: "index_related_documents_on_form_id_and_language_and_type", unique: true
    t.index ["upvs_form_id"], name: "index_upvs_form_related_documents_on_form_id"
  end

  create_table "upvs_forms", force: :cascade do |t|
    t.string "identifier", null: false
    t.string "version", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier", "version"], name: "index_forms_on_identifier_version", unique: true
  end

  create_table "upvs_service_with_form_allow_rules", force: :cascade do |t|
    t.string "name"
    t.string "institution_uri", null: false
    t.string "institution_name"
    t.string "schema_url"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_filter_visibilities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.integer "position"
    t.bigint "filter_id", null: false
    t.index ["filter_id"], name: "index_user_filter_visibilities_on_filter_id"
    t.index ["user_id"], name: "index_user_filter_visibilities_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "tenant_id"
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "saml_identifier"
    t.datetime "notifications_last_opened_at"
    t.datetime "notifications_reset_at"
    t.index "tenant_id, lower((email)::text)", name: "index_users_on_tenant_id_and_lowercase_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_connections", "tenants"
  add_foreign_key "archived_object_versions", "archived_objects"
  add_foreign_key "archived_objects", "message_objects"
  add_foreign_key "audit_logs", "message_threads", on_delete: :nullify
  add_foreign_key "audit_logs", "tenants", on_delete: :nullify
  add_foreign_key "audit_logs", "users", column: "actor_id", on_delete: :nullify
  add_foreign_key "automation_actions", "automation_rules"
  add_foreign_key "automation_conditions", "automation_rules"
  add_foreign_key "automation_rules", "tenants"
  add_foreign_key "automation_rules", "users"
  add_foreign_key "boxes", "api_connections"
  add_foreign_key "boxes", "tenants"
  add_foreign_key "filter_subscriptions", "filters"
  add_foreign_key "filter_subscriptions", "tenants"
  add_foreign_key "filter_subscriptions", "users"
  add_foreign_key "filters", "tags"
  add_foreign_key "filters", "tenants", on_delete: :cascade
  add_foreign_key "filters", "users", column: "author_id", on_delete: :cascade
  add_foreign_key "folders", "boxes"
  add_foreign_key "govbox_folders", "govbox_folders", column: "parent_folder_id"
  add_foreign_key "govbox_messages", "govbox_folders", column: "folder_id"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "groups", "tenants"
  add_foreign_key "message_drafts_imports", "boxes"
  add_foreign_key "message_object_data", "message_objects"
  add_foreign_key "message_objects", "messages"
  add_foreign_key "message_objects_tags", "message_objects"
  add_foreign_key "message_objects_tags", "tags"
  add_foreign_key "message_relations", "messages"
  add_foreign_key "message_relations", "messages", column: "related_message_id"
  add_foreign_key "message_templates", "tenants"
  add_foreign_key "message_thread_merge_identifiers", "message_threads"
  add_foreign_key "message_thread_notes", "message_threads"
  add_foreign_key "message_threads", "boxes"
  add_foreign_key "message_threads", "folders"
  add_foreign_key "message_threads_tags", "message_threads"
  add_foreign_key "message_threads_tags", "tags"
  add_foreign_key "messages", "message_drafts_imports", column: "import_id"
  add_foreign_key "messages", "message_threads"
  add_foreign_key "messages", "users", column: "author_id"
  add_foreign_key "messages_tags", "messages"
  add_foreign_key "messages_tags", "tags"
  add_foreign_key "nested_message_objects", "message_objects", on_delete: :cascade
  add_foreign_key "notifications", "filter_subscriptions", on_delete: :cascade
  add_foreign_key "notifications", "message_threads", on_delete: :cascade
  add_foreign_key "notifications", "messages", on_delete: :cascade
  add_foreign_key "notifications", "users", on_delete: :cascade
  add_foreign_key "searchable_message_threads", "message_threads", on_delete: :cascade
  add_foreign_key "stats_message_submission_requests", "boxes"
  add_foreign_key "tag_groups", "groups"
  add_foreign_key "tag_groups", "tags"
  add_foreign_key "tags", "tenants"
  add_foreign_key "tags", "users", column: "owner_id"
  add_foreign_key "upvs_form_related_documents", "upvs_forms"
  add_foreign_key "user_filter_visibilities", "filters"
  add_foreign_key "user_filter_visibilities", "users"
  add_foreign_key "users", "tenants"
end
