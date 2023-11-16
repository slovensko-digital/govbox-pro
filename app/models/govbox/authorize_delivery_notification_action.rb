class Govbox::AuthorizeDeliveryNotificationAction
  def self.run(message_threads)
    jobs_batch = GoodJob::Batch.new
    message_for_delivery = message_threads.map(&:messages).flatten

    results = message_for_delivery.map do |message|
      jobs_batch.add { ::Message.authorize_delivery_notification(message, schedule_sync: false) }
    end

    boxes_to_sync = message_for_delivery.map(&:thread).map(&:folder).map(&:box).uniq
    jobs_batch.enqueue(on_finish: Govbox::ScheduleDelayedSyncBoxJob, boxes: boxes_to_sync)

    results.select { |value| value }.present?
  end
end
