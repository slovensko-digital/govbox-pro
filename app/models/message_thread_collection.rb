class MessageThreadCollection
  DELIVERED_AT = :last_message_delivered_at
  ID = :message_thread_id
  CURSOR_PARAMS = [DELIVERED_AT, ID]
  PER_PAGE = 20
  DIRECTION = :desc

  def self.init_cursor(cursor_params = nil)
    cursor_params ||= {}
    {
      DELIVERED_AT => cursor_params[DELIVERED_AT] ? millis_to_time(cursor_params[DELIVERED_AT]) : Time.now,
      ID => cursor_params[ID]
    }
  end

  def self.serialize_cursor(cursor)
    return nil if cursor.nil?

    cursor[DELIVERED_AT] = time_to_millis(cursor[DELIVERED_AT])
    cursor
  end

  # TODO
  # def self.exists_by_query()

  def self.all(scope: MessageThread, search_permissions:, query: "", cursor:)
    parsed_query = Searchable::MessageThreadQuery.parse(query)
    filter = Searchable::MessageThreadQuery.labels_to_ids(
      parsed_query,
      tenant: search_permissions.fetch(:tenant)
    )

    ids, next_cursor, highlights = Searchable::MessageThread.search_ids(
      filter,
      search_permissions: search_permissions,
      cursor: cursor,
      direction: DIRECTION,
      per_page: PER_PAGE
    ).fetch_values(:ids, :next_cursor, :highlights)

    message_thread_scope = scope.
      where(id: ids).
      order(Pagination.order_clause(searchable_cursor_to_cursor(cursor), DIRECTION))

    records = message_thread_scope.select(
      'message_threads.*',
      '(select bool_and(read) from messages where messages.message_thread_id = message_threads.id) as all_read',
      # TODO: - mame tu velmi hruby sposob ako zistit, s kym je dany thread komunikacie, vedeny, len pre ucely zobrazenia. Dohodnut aj s @Taja, co s tym
      '(select max(coalesce(recipient_name)) from messages where messages.id = (select m.id FROM (select * from messages where messages.message_thread_id = message_threads.id ORDER BY messages.delivered_at) as m LIMIT 1)) as recipient',
      '(select max(coalesce(sender_name)) from messages where messages.id = (select m.id FROM (select * from messages where messages.message_thread_id = message_threads.id ORDER BY messages.delivered_at) as m LIMIT 1)) as sender',
      '(select messages.outbox from messages where messages.id = (select m.id FROM (select * from messages where messages.message_thread_id = message_threads.id ORDER BY messages.delivered_at) as m LIMIT 1)) as is_outbox',
      # last_message_id - potrebujeme kvoli spravnej linke na konkretny message, ktory chceme otvorit, a nech to netahame potom pre kazdy thread
      '(select max(messages.id) from messages where messages.message_thread_id = message_threads.id and messages.delivered_at = message_threads.last_message_delivered_at) as last_message_id',
    )

    records.each { |row| row.search_highlight = highlights[row.id] }

    {
      records: records,
      next_cursor: next_cursor
    }
  end

  def self.searchable_cursor_to_cursor(cursor)
    return nil if cursor.nil?

    {
      DELIVERED_AT => cursor[DELIVERED_AT],
      :id => cursor[ID]
    }
  end

  def self.time_to_millis(time)
    time.strftime('%s%L').to_f
  end

  def self.millis_to_time(millis)
    Time.at(millis.to_f / 1000)
  end
end
