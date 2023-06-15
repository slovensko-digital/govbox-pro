module Pagination
  def paginate(collection:, params:, cursor:)
    rows = build_query(collection, params, cursor)
    [rows, next_cursor(rows, cursor)]
  end

  def build_query(collection, params, cursor)
    collection
      .where(where_clause(cursor, params[:direction]), *where_values(cursor))
      .order(order_clause(cursor, params))
      .limit(params[:items_per_page])
  end

  def where_clause(cursor, direction)
    # build where clause for where((attr1.name, attr2.name) < '?, ?', (attr1.value, attr2.value))
    where_args_string = ''
    cursor.each do |attr|
      if attr[:value]
        where_args_string += ',' unless where_args_string.empty?
        where_args_string += attr[:name]
      end
    end
      # only filter when value provided in cursor
      # create string-list of cursor arg names
    questionmarks = where_args_string.gsub(/[^,]+/, '?')
    "(#{where_args_string})" + (direction == 'desc' ? '<' : '>') + "(#{questionmarks})"
  end

  def order_clause(cursor, params)
    cursor.map { |attr| "#{attr[:name]} #{params[:direction]}" }
  end

  def where_values(cursor)
    cursor.select { |attr| attr[:value] }.map{ |attr| attr[:value] }
  end

  def next_cursor(collection, cursor)
    next_cursor = {}
    if collection.any?
      cursor.each do |attr| 
        next_cursor[attr[:name].to_sym] = collection.last[attr[:name]]
      end
    end
    next_cursor
  end
end
