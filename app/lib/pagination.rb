module Pagination
  def self.paginate(collection:, cursor:, direction: 'desc', items_per_page: 10)
    rows = collection
           .where(where_clause(cursor, direction), *cursor.compact.values)
           .order(order_clause(cursor, direction))
           .limit(items_per_page + 1) # +1 needed to find out if we need next page
    if rows.count > items_per_page
      next_cursor = row_to_cursor(rows.second_to_last, cursor)
      rows.limit(items_per_page)
    end
    [rows, next_cursor]
  end

  def self.row_to_cursor(row, cursor)
    cursor.map { |key, _value| [key, row[extract_attr_name(key)]] }.to_h
  end

  def self.extract_attr_name(table_dot_attr_path)
    table_dot_attr_path.to_s.split('.')[-1]
  end

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
