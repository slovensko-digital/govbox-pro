module MessageThreadHelper
  def filtered_message_threads_path(filter: nil, query: nil)
    args = {
      filter_id: filter&.id,
      q: query
    }.compact

    message_threads_path(args)
  end

  def self.show_recipient?(message_thread)
    !message_thread.box.single_recipient? && message_thread.is_outbox && message_thread.recipient.present?
  end

  def self.show_sender?(message_thread)
    message_thread.box.single_recipient? || (!message_thread.is_outbox && message_thread.sender.present?)
  end
end
