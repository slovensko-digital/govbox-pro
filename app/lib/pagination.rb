module Pagination
  def self.paginate(collection:, cursor:, direction: 'desc', items_per_page: 10)
    rows =
      collection
        .where(where_clause(cursor, direction), *cursor.compact.values)
        .order(order_clause(cursor, direction))
        .limit(items_per_page)
    last_row = rows&.last
    next_cursor = cursor.map { |key, _value| [key, last_row[key.to_s.split('.')[-1]]] }.to_h if last_row
    [rows, next_cursor]
  end

  private

  def self.order_clause(cursor, direction)
    cursor.keys.map { |key| "#{key} #{direction}" }.join(',')
  end

  def self.where_clause(cursor, direction)
    # build where clause for where((attr1.name, attr2.name) < '?, ?', (attr1.value, attr2.value))
    # only for keys where value is provided (therefore .compact)
    where_args_string = cursor.compact.keys.join(',')
    questionmarks = cursor.compact.keys.map { '?' }.join(',')
    "(#{where_args_string})" + (direction.to_s == 'desc' ? '<' : '>') + "(#{questionmarks})"
  end
end
