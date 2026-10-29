class TagsFilter
  attr_reader :all_tags, :filtered_ids, :filter_query, :manageable_ids

  def initialize(tag_scope:, filter_query: "", manageable_scope: nil)
    @all_tags = tag_scope.load
    @filter_query = filter_query
    all_ids = @all_tags.map(&:id)
    @manageable_ids = Set.new(manageable_scope ? manageable_scope.pluck(:id) : all_ids)

    filtered_ids = if filter_query.present?
      @all_tags.where('unaccent(tags.name) ILIKE unaccent(?)', "%#{filter_query}%").pluck(:id)
    else
      all_ids
    end
    @filtered_ids = Set.new(filtered_ids)
  end

  def any_filtered_results?
    @filtered_ids.present?
  end
end
