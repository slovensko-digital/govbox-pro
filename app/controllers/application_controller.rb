class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  after_action :verify_authorized
  after_action :verify_policy_scoped, if: -> { action_name == "index" }
  before_action :set_menu_context
  helper_method :current_search_query

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def pundit_user
    Current.user
  end

  def set_menu_context
    return unless Current.user

    @tags = policy_scope(Tag, policy_scope_class: TagPolicy::ScopeListable).where(visible: true).order(:name)
    personalized = Current.tenant.feature_enabled?(:personalized_filters)
    @filters = personalized ? Current.user.pinned_filters.to_a : policy_scope(Filter, policy_scope_class: FilterPolicy::ScopeShowable).order(:position)
    @menu_filters = @filters
    @system_tags = if personalized
      system_tags = Current.tenant.tags.visible.where.not(type: SimpleTag.to_s)
      owned_signing_tags = system_tags.where(type: [SignatureRequestedFromTag.to_s, SignedByTag.to_s], owner_id: Current.user.id)
      selected = system_tags.where.not(type: [SignatureRequestedFromTag.to_s, SignedByTag.to_s]).or(owned_signing_tags).order(:name, :id).to_a
      tag_queries = selected.map { |tag| "label:(#{tag.name})" }.to_set
      @menu_filters = @filters.reject { |filter| filter.common? && tag_queries.include?(filter.query) }
      signing_tags = Current.tenant.tags.where(type: [SignatureRequestedFromTag.to_s, SignedByTag.to_s])
      other_signing_tags = signing_tags.where.not(owner_id: Current.user.id).or(signing_tags.where(owner_id: nil))
      hidden_signing_queries = other_signing_tags.pluck(:name).map { |name| "label:(#{name})" }.to_set
      @menu_filters.reject! { |filter| hidden_signing_queries.include?(filter.query) }
      selected
    else
      []
    end
    @menu = SidebarMenu.new(controller_name, action_name, { tags: @tags, filters: @menu_filters, system_tags: @system_tags, personalized: personalized, query: current_search_query })
  end

  def current_search_query
    return params[:q].to_s.strip if params.key?(:q)
    if Current.user && Current.tenant.feature_enabled?(:personalized_filters) && controller_name == "message_threads" && action_name.in?(%w[index scroll bulk_actions])
      return @filters.first&.query.to_s
    end

    ""
  end

  private

  def user_not_authorized(exception)
    flash[:alert] = "Prístup bol zamietnutý"
    redirect_to(request.referer || root_path)
  end
end
