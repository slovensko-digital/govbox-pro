class MessageThreadCollection
  DELIVERED_AT = :last_message_delivered_at
  ID = :message_thread_id
  CURSOR_PARAMS = [DELIVERED_AT, ID]
  PER_PAGE = 20
  DIRECTION = :desc

  def self.init_cursor(cursor_params)
    cursor_params = cursor_params || {}

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

  def self.all(scope: nil, search_permissions:, query: nil, cursor:)
    parsed_query = Searchable::MessageThreadQuery.parse(query.to_s)
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

    message_thread_scope = (scope || MessageThread).
      where(id: ids).
      order(Pagination.order_clause(searchable_cursor_to_cursor(cursor), DIRECTION))

    records = message_thread_scope.select(
      'message_threads.*',
      '(select bool_and(read) from messages where messages.message_thread_id = message_threads.id) as all_read',
      # TODO: - mame tu velmi hruby sposob ako zistit, s kym je dany thread komunikacie, vedeny, len pre ucely zobrazenia. Dohodnut aj s @Taja, co s tym
      'coalesce((select max(coalesce(recipient_name)) from messages where messages.message_thread_id = message_threads.id),
        (select max(coalesce(sender_name)) from messages where messages.message_thread_id = message_threads.id)) as with_whom',
      # last_message_id - potrebujeme kvoli spravnej linke na konkretny message, ktory chceme otvorit, a nech to netahame potom pre kazdy thread
      '(select max(messages.id) from messages where messages.message_thread_id = message_threads.id and messages.delivered_at = message_threads.last_message_delivered_at) as last_message_id'
    )

    records.map { |row| row.search_highlight = highlights[row.id] }

    {
      records: records,
      next_cursor: next_cursor,
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
