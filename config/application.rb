require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

if ['development', 'test'].include? ENV['RAILS_ENV']
  Dotenv::Rails.load
end

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

    config.autoload_paths += Dir[File.join(Rails.root, 'app', 'models', 'validators')]

    config.active_record.encryption.primary_key = ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY']
    config.active_record.encryption.deterministic_key = ENV['ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY']
    config.active_record.encryption.key_derivation_salt = ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT']

    config.active_job.queue_adapter = :good_job
    config.active_job.default_queue_name = :medium_priority
    config.action_mailer.deliver_later_queue_name = :high_priority

    config.good_job.enable_cron = true
    if ENV['AUTO_SYNC_BOXES'] == "ON"
      config.good_job.cron = {
        sync_boxes: {
          cron: "1 */2 * * *",  # run every 2 hours (even), "00:01", "02:01", "04:01", ...
          class: "Govbox::SyncAllBoxesJob",
          description: "Regular job to synchronize all boxes"
        }
      }

      config.good_job.cron['sync_fs_boxes'] = {
        cron: "1 1-23/2 * * *",  # run every 2 hours (odd), "01:01", "03:01", "05:01", ...
        class: "Fs::SyncAllBoxesJob",
        description: "Regular job to synchronize all boxes"
      }
    end

    config.good_job.cron['check_messages_mapping'] = {
      cron: "30 7 * * *",  # run every day at 7:30 am
      class: "Govbox::CheckMessagesMappingJob",
      description: "Regular job to check messages mapping"
    }

    config.good_job.cron['check_archived_documents'] = {
      cron: "30 3 * * *",  # run every day at 3:30 am
      class: "Archivation::ArchiveAllArchivedMessageThreadsJob",
      description: "Regular job to archive message_threads"
    }

    if ENV['AUTO_SYNC_FS_FORMS'] == "ON"
      config.good_job.cron['fetch_fs_forms'] = {
        cron: "0 */12 * * *",  # run every 12 hours
        class: "Fs::FetchFormsJob",
        description: "Regular job to fetch Fs::Forms"
      }
    end

    if ENV['AUTO_SYNC_UPVS_FORMS'] == "ON"
      config.good_job.cron['fetch_upvs_forms_related_documents'] = {
        cron: "0 */12 * * *",  # run every 12 hours
        class: "Upvs::FetchFormRelatedDocumentsJob",
        description: "Regular job to fetch Upvs::FormRelatedDocuments"
      }
    end

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
