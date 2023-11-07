class TagsFilter
  attr_reader :all_tags, :filtered_ids, :filter_query

  def initialize(tag_scope:, filter_query: "")
    @all_tags = tag_scope
    @filter_query = filter_query

    @filtered_ids = @all_tags
    if filter_query
      @filtered_ids = @filtered_ids.where('unaccent(name) ILIKE unaccent(?)', "%#{filter_query}%")
    end
    @filtered_ids = Set.new(@filtered_ids.pluck(:id))
  end

  def any_filtered_results?
    @filtered_ids.present?
  end
end
