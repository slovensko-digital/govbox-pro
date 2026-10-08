class TagsFilter
  attr_reader :all_tags, :filtered_ids, :filter_query, :manageable_ids

  def initialize(tag_scope:, filter_query: "", manageable_scope: nil)
    @all_tags = tag_scope
    @filter_query = filter_query
    @manageable_ids = Set.new((manageable_scope || tag_scope).pluck(:id))

    @filtered_ids = @all_tags
    if filter_query
      @filtered_ids = @filtered_ids.where('unaccent(tags.name) ILIKE unaccent(?)', "%#{filter_query}%")
    end
    @filtered_ids = Set.new(@filtered_ids.pluck(:id))
  end

  def any_filtered_results?
    @filtered_ids.present?
  end
end
