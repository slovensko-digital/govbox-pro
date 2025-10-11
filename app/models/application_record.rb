class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  class FailedToAcquireLockError < StandardError
  end

  def self.with_advisory_lock!(lock_name, options = {}, &block)
    result = with_advisory_lock_result(lock_name, options, &block)
    if result.lock_was_acquired?
      result.result
    else
      raise FailedToAcquireLockError
    end
  end

  def self.count_estimate_for(relation = all)
    rel =
      relation
        .except(:select, :order, :includes, :preload, :eager_load) # planner doesn't need these
        .select(Arel.sql('1')) # SELECT list doesn't matter, keep it simple

    sql  = rel.to_sql
    qsql = connection.quote(sql) # safe quoting

    connection.select_value("SELECT count_estimate(#{qsql})").to_i
  rescue ActiveRecord::StatementInvalid
    # Fallback if something (permissions, CTE edge cases, etc.) breaks
    nil
  end
end
