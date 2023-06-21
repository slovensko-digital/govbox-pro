module Pagination
  def self.paginate(collection:, params:, cursor:)
    rows = build_query(collection, params, cursor)
    [rows, next_cursor(rows, cursor)]
  end

  private

  def self.build_query(collection, params, cursor)
    collection
      .where(where_clause(cursor, params[:direction]), *where_values(cursor))
      .order(order_clause(cursor, params))
      .limit(params[:items_per_page])
  end

  def self.where_clause(cursor, direction)
    # build where clause for where((attr1.name, attr2.name) < '?, ?', (attr1.value, attr2.value))
    where_args_string = ''
    # create string-list of cursor arg names
    cursor.each do |attr|
      # only filter when value provided in cursor
      if attr[:value]
        where_args_string += ',' unless where_args_string.empty?
        where_args_string += attr[:name]
      end
    end
    questionmarks = where_args_string.gsub(/[^,]+/, '?')
    "(#{where_args_string})" + (direction == 'desc' ? '<' : '>') + "(#{questionmarks})"
  end

  def self.order_clause(cursor, params)
    cursor.map { |attr| "#{attr[:name]} #{params[:direction]}" }
  end

  def self.where_values(cursor)
    cursor.select { |attr| attr[:value] }.map{ |attr| attr[:value] }
  end

  def self.next_cursor(collection, cursor)
    next_cursor = {}
    if collection.any?
      cursor.each do |attr| 
        next_cursor[attr[:name].to_sym] = collection.last[attr[:name]]
      end
    end
    next_cursor
  end
end
