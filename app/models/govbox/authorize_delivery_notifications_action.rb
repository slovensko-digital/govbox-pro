class Govbox::AuthorizeDeliveryNotificationsAction
  def self.run(message_threads)
    jobs_batch = GoodJob::Batch.new
    messages = message_threads.map(&:messages).flatten

    results = messages.map do |message|
      jobs_batch.add { ::Message.authorize_delivery_notification(message, schedule_sync: false) }
    end

    tenant = messages.first.thread.box.tenant
    boxes_to_sync = tenant.boxes.joins(folders: { message_threads: :messages }).where(messages: { id: messages.map(&:id) } ).uniq
    jobs_batch.enqueue(on_finish: Govbox::ScheduleDelayedSyncBoxJob, boxes: boxes_to_sync)

    results.select { |value| value }.present?
  end
end
