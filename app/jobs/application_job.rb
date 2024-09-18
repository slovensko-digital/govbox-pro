class ApplicationJob < ActiveJob::Base
  include Rollbar::ActiveJob

  queue_as :default

  queue_with_priority do
    case queue_name.to_sym
    when :asap then -1000
    when :default then 0
    when :later then 1000
    else
      raise "Unable to assign default priority to a job on #{queue_name} queue"
    end
  end

  retry_on StandardError, wait: :polynomially_longer, attempts: Float::INFINITY
end
