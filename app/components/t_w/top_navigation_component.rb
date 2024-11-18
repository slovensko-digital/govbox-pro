class TW::TopNavigationComponent < ViewComponent::Base
  include MessageThreadHelper

  def query
    Searchable::QueryBuilder.new(
      filter_id: nil,
      query: query_params[:q],
      user: Current.user
    ).build
  end

  def query_params
    params
      .permit(:filter_id, :q)
      .slice(:filter_id, :q)
  end
end
