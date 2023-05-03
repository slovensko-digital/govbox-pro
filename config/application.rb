require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GovboxPro
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    config.middleware.use Rack::Attack

    config.active_record.schema_format = :ruby

    # config.i18n.load_path += Dir[Rails.root.join 'config', 'locales', '**', '*.{rb,yml}']
    config.i18n.default_locale = :sk

    config.active_record.default_timezone = :utc
    config.time_zone = 'Europe/Bratislava'

    config.autoload_paths += Dir[File.join(Rails.root, 'app', 'models', 'validators')]

    config.active_job.queue_adapter = :good_job
    config.active_job.default_queue_name = :medium_priority
    config.action_mailer.deliver_later_queue_name = :high_priority

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
