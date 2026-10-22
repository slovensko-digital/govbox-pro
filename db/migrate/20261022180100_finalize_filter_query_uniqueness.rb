# frozen_string_literal: true

class FinalizeFilterQueryUniqueness < ActiveRecord::Migration[7.1]
  NORMALIZED_QUERY = "btrim(query, E' \\t\\n\\r\\f' || chr(11))".freeze

  def collision_report
    connection.select_all(<<~SQL).to_a
      SELECT filters.tenant_id, filters.common,
             CASE WHEN filters.common THEN NULL ELSE filters.author_id END AS owner_id,
             #{NORMALIZED_QUERY} AS query_key,
             array_agg(filters.id ORDER BY filters.id) AS filter_ids,
             (SELECT count(DISTINCT subscriptions.user_id)
                FROM filter_subscriptions subscriptions
               WHERE subscriptions.filter_id = ANY(array_agg(filters.id))) AS subscribing_users
        FROM filters
       GROUP BY filters.tenant_id, filters.common, owner_id, query_key
      HAVING count(*) > 1
    SQL
  end

  def up
    collisions = collision_report
    raise "Duplicate saved queries require explicit resolution: #{collisions.inspect}" if collisions.any?

    execute "UPDATE filters SET query = #{NORMALIZED_QUERY}"
    add_index :filters, [:tenant_id, :query], unique: true, where: "common = TRUE", name: "unique_common_filter_query"
    add_index :filters, [:tenant_id, :author_id, :query], unique: true, where: "common = FALSE", name: "unique_personal_filter_query"
    add_check_constraint :filters, "common OR author_id IS NOT NULL", name: "personal_filter_has_author"
  end

  def down
    remove_check_constraint :filters, name: "personal_filter_has_author"
    remove_index :filters, name: "unique_personal_filter_query"
    remove_index :filters, name: "unique_common_filter_query"
  end
end
