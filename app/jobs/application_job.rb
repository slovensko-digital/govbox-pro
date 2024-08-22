class ApplicationJob < ActiveJob::Base
  include Rollbar::ActiveJob

  queue_as :medium_priority

  queue_with_priority do
    case queue_name.to_sym
    when :highest_priority then -1000
    when :high_priority then -100
    when :medium_priority then 0
    when :low_priority then 100
    when :lowest_priority then 1000
    else
      raise "Unable to assign default priority to a job on #{queue_name} queue"
    end
  end

  retry_on StandardError, wait: :polynomially_longer, attempts: Float::INFINITY
end
