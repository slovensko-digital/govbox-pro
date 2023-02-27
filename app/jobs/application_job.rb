class ApplicationJob < ActiveJob::Base
  include Rollbar::ActiveJob

  queue_as :medium_priority

  queue_with_priority do
    case queue_name.to_sym
    when :high_priority then 50
    when :medium_priority then 100
    when :low_priority then 200
    else
      raise "Unable to assign default priority to a job on #{queue_name} queue"
    end
  end
end
