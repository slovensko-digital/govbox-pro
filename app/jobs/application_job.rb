class ApplicationJob < ActiveJob::Base
  include Rollbar::ActiveJob

  retry_on StandardError, wait: :polynomially_longer, attempts: Float::INFINITY
end
