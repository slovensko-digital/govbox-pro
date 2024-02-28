class TW::TopNavigationComponent < ViewComponent::Base
  include MessageThreadHelper

  def query
    query_params = params
      .permit(:filter_id, :q)
      .slice(:filter_id, :q)

    Searchable::QueryBuilder.new(
      filter_id: query_params[:filter_id],
      query: query_params[:q],
    ).build
  end
end
