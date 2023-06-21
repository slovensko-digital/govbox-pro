module Pagination
  def paginate(collection:, cursor:, direction: 'desc', items_per_page: 10)
    rows = collection
           .where(where_clause(cursor, direction), *cursor.compact.values)
           .order(cursor.keys.map { |key| "#{key} #{direction}" }.join(','))
           .limit(items_per_page)
    next_cursor = cursor.map { |key, _value| [key, rows.last[key]]}.to_h unless rows.empty?
    [rows, next_cursor]
  end

  private

  def where_clause(cursor, direction)
    # build where clause for where((attr1.name, attr2.name) < '?, ?', (attr1.value, attr2.value))
    # only for keys where value is provided (therefore .compact)
    where_args_string = cursor.compact.keys.join(',')
    questionmarks = cursor.compact.keys.map { '?' }.join(',')
    "(#{where_args_string})" + (direction == 'desc' ? '<' : '>') + "(#{questionmarks})"
  end
end
