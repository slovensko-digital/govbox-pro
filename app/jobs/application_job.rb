class ApplicationJob < ActiveJob::Base
  include Rollbar::ActiveJob

  queue_as :default

  attr_accessor :job_context

  def set(options = {})
    # :nodoc:
    self.job_context = options[:job_context]
    super
  end

  def serialize
    super.merge(
      job_context: job_context
    )
  end

  def deserialize(job_data)
    super
    self.job_context = job_data["job_context"]
  end

  before_enqueue do |job|
    job.job_context = Thread.current[:job_context] if Thread.current[:job_context].present?
    job.queue_name = job.job_context if job.job_context.present?
    puts 1
  end

  around_perform do |job, block|
    Thread.current[:job_context] = job.job_context if job.job_context.present?
    block.call
  ensure
    Thread.current[:job_context] = nil
  end

  queue_with_priority do
    case queue_name.to_sym
    when :asap then -1000
    when :default, :automation then 0
    when :later then 1000
    else
      raise "Unable to assign default priority to a job on #{queue_name} queue"
    end
  end

  retry_on StandardError, wait: :polynomially_longer, attempts: Float::INFINITY
end
