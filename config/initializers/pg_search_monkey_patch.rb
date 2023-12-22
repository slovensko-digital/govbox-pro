# frozen_string_literal: true

# Monkey patch that adds scope pushing down conditions to subselect
module PgSearch
  class ScopeOptions
    def apply(scope)
      scope = include_table_aliasing_for_rank(scope)
      rank_table_alias = scope.pg_search_rank_table_alias(include_counter: true)

      scope
        .joins(rank_join(rank_table_alias, scope))
        .order(Arel.sql("#{rank_table_alias}.rank DESC, #{order_within_rank}"))
        .extend(WithPgSearchRank)
        .extend(WithPgSearchHighlight[feature_for(:tsearch)])
    end

    def rank_join(rank_table_alias, scope)
      "INNER JOIN (#{subquery(scope).to_sql}) AS #{rank_table_alias} ON #{primary_key} = #{rank_table_alias}.pg_search_id"
    end

    def subquery(scope)
      scope
        .select("#{primary_key} AS pg_search_id")
        .select("#{rank} AS rank")
        .joins(subquery_join)
        .where(conditions)
        .limit(nil)
        .offset(nil)
    end
  end
end
