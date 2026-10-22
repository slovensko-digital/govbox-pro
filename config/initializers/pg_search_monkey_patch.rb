# frozen_string_literal: true

# Monkey patch that adds scope pushing down conditions to subselect.
#
# pg_search builds the rank subquery from `model.unscoped`, so the fulltext
# match runs over every tenant's rows and only the outer query filters them.
# We build it from the current scope instead, so tenant/tag conditions are
# applied inside the subselect too.
module PgSearch
  class ScopeOptions
    def apply(scope)
      scope = include_table_aliasing_for_rank(scope)
      rank_table_alias = scope.pg_search_rank_table_alias(include_counter: true)
      rank_subquery = subquery(scope).arel.as(rank_table_alias)

      scope
        .joins(rank_join(rank_subquery))
        .order(rank_subquery[:rank].desc)
        .order(order_within_rank)
        .extend(WithPgSearchRank)
        .extend(WithPgSearchHighlight[feature_for(:tsearch)])
    end

    def subquery(scope)
      scope
        .select(model.arel_table[model.primary_key].as("pg_search_id"))
        .select(rank.as("rank"))
        .joins(subquery_join)
        .where(conditions)
        .limit(nil)
        .offset(nil)
    end
  end
end
