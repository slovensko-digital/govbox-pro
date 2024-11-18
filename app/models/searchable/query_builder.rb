class Searchable::QueryBuilder
  attr_reader :filter, :filter_id, :query, :user

  def initialize(filter: nil, filter_id: nil, query: nil, user: nil)
    @filter = filter
    @filter_id = filter_id
    @query = query
    @user = user
  end

  def build
    if filter.nil? && filter_id.present?
      @filter = FilterPolicy::ScopeShowable.new(user, Filter).resolve.find_by(id: filter_id)
    end

    [
      filter&.query,
      query,
    ]
      .compact
      .map(&:strip)
      .join(' ')
  end
end