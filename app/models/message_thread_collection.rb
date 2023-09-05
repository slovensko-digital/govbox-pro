class MessageThreadCollection
  def self.thread_ids_for_tag(tag_id)
    Tag.find(tag_id).message_thread_ids
  end

  def self.treads_ids_without_custom_tags()
    Tag.joins(:message_threads_tags).where('tags.name not like ?', 'slovensko.sk:%').pluck('message_threads_tags.message_thread_id')
  end

  def self.all(message_thread_scope:, tag_id: nil, no_tag: false)
    message_thread_scope ||= MessageThread

    if tag_id
      message_thread_scope = message_thread_scope.where(id: thread_ids_for_tag(tag_id))
    end

    if no_tag
      message_thread_scope = message_thread_scope.where.not(id: treads_ids_without_custom_tags())
    end

    message_thread_scope.select(
      'message_threads.*',
      '(select bool_and(read) from messages where messages.message_thread_id = message_threads.id) as all_read',
      # TODO: - mame tu velmi hruby sposob ako zistit, s kym je dany thread komunikacie, vedeny, len pre ucely zobrazenia. Dohodnut aj s @Taja, co s tym
      'coalesce((select max(coalesce(recipient_name)) from messages where messages.message_thread_id = message_threads.id),
        (select max(coalesce(sender_name)) from messages where messages.message_thread_id = message_threads.id)) as with_whom',
      # last_message_id - potrebujeme kvoli spravnej linke na konkretny message, ktory chceme otvorit, a nech to netahame potom pre kazdy thread
      '(select max(messages.id) from messages where messages.message_thread_id = message_threads.id and messages.delivered_at = message_threads.last_message_delivered_at) as last_message_id'
    )
  end
end
