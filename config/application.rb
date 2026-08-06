require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv::Rails.load if ['development', 'test'].include? ENV['RAILS_ENV']

module GovboxPro
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    config.middleware.use Rack::Attack

    config.active_record.schema_format = :ruby

    # config.i18n.load_path += Dir[Rails.root.join 'config', 'locales', '**', '*.{rb,yml}']
    config.i18n.default_locale = :sk

    config.active_record.default_timezone = :utc
    config.time_zone = 'Europe/Bratislava'

    config.autoload_paths += Dir[Rails.root.join("app/models/validators").to_s]

    config.active_record.encryption.primary_key = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY', nil)
    config.active_record.encryption.deterministic_key = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY', nil)
    config.active_record.encryption.key_derivation_salt = ENV.fetch('ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT', nil)

    previous_primary_key = ENV['ACTIVE_RECORD_ENCRYPTION_PREVIOUS_PRIMARY_KEY']
    if previous_primary_key.present?
      previous_key_derivation_salt = ENV.fetch(
        'ACTIVE_RECORD_ENCRYPTION_PREVIOUS_KEY_DERIVATION_SALT',
        ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT']
      )
      derived_secret = ActiveSupport::KeyGenerator.new(
        previous_primary_key,
        hash_digest_class: config.active_record.encryption.hash_digest_class
      ).generate_key(previous_key_derivation_salt, ActiveRecord::Encryption.cipher.key_length)

      config.active_record.encryption.previous = [{
        key_provider: ActiveRecord::Encryption::KeyProvider.new(
          ActiveRecord::Encryption::Key.new(derived_secret)
        )
      }]
      config.active_record.encryption.extend_queries = true
    end

    config.active_job.queue_adapter = :good_job
    config.active_job.default_queue_name = :default
    config.action_mailer.deliver_later_queue_name = :asap

    config.good_job.enable_cron = true
    config.good_job.smaller_number_is_higher_priority = true
    config.good_job.cleanup_preserved_jobs_before_seconds_ago = 1.day
    config.good_job.cleanup_discarded_jobs = false

    Rails.application.routes.default_url_options[:host] = ENV.fetch('DOMAIN_NAME')

    if ENV['AUTO_SYNC_BOXES'] == "ON"
      config.good_job.cron = {
        sync_boxes: {
          cron: "1 */2 * * *", # run every 2 hours (even), "00:01", "02:01", "04:01", ...
          class: "Govbox::SyncAllBoxesJob",
          description: "Regular job to synchronize all boxes",
          set: { job_context: :low }
        }
      }

      config.good_job.cron[:sync_fs_boxes] = {
        cron: "30 0 * * *", # run every day at 0:30 am
        class: "Fs::SyncAllBoxesJob",
        description: "Regular job to synchronize all boxes",
        set: { job_context: :later }
      }
    end

    if ENV['AUTO_SYNC_UPVS_FORMS'] == "ON"
      config.good_job.cron[:fetch_upvs_forms_related_documents] = {
        cron: "30 1 * * *", # run every day at 1:30 am
        class: "Upvs::FetchFormRelatedDocumentsJob",
        description: "Regular job to fetch Upvs::FormRelatedDocuments",
        set: { job_context: :later }
      }
    end

    if ENV['AUTO_SYNC_FS_FORMS'] == "ON"
      config.good_job.cron[:fetch_fs_forms] = {
        cron: "30 2 * * *", # run every day at 2:30 am
        class: "Fs::FetchFormsJob",
        description: "Regular job to fetch Fs::Forms",
        set: { job_context: :later }
      }
    end

    config.good_job.cron[:check_archived_documents] = {
      cron: "30 3 * * *", # run every day at 3:30 am
      class: "Archivation::ArchiveAllArchivedMessageThreadsJob",
      description: "Regular job to archive message_threads",
      set: { job_context: :later }
    }

    config.good_job.cron[:autoload_fs_boxes] = {
      cron: "00 6 * * *", # run every day at 6:00 am
      class: "Fs::BoxifyAllApiConnectionsJob",
      description: "Regular job to autoload FS boxes",
      set: { job_context: :later }
    }

    config.good_job.cron[:check_messages_mapping] = {
      cron: "30 7 * * *", # run every day at 7:30 am
      class: "Govbox::CheckMessagesMappingJob",
      description: "Regular job to check messages mapping",
      set: { job_context: :later }
    }

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end

Rails.application.routes.default_url_options[:host] = ENV.fetch('DOMAIN_NAME')
