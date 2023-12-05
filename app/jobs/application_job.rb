class ApplicationJob < ActiveJob::Base
  include Rollbar::ActiveJob

  retry_on StandardError, wait: :exponentially_longer, attempts: Float::INFINITY
end
