class Settings::UserHiddenItemsController < ApplicationController
  before_action :set_user_hidden_item, only: [:destroy]

  def index
    authorize UserHiddenItem
    if params[:type] == 'Tag'
      set_tag_items
    elsif params[:type] == 'Filter'
      set_filter_items
    end
  end

  def create
    authorize UserHiddenItem
    Current.user.user_hidden_items.create(user_hidden_item_params)
    redirect_back fallback_location: settings_user_hidden_items_path
  end

  def destroy
    authorize @user_hidden_item
    @user_hidden_item.destroy
    redirect_back fallback_location: settings_user_hidden_items_path
  end

  private

  def set_tag_items
    @items = policy_scope(Tag, policy_scope_class: TagPolicy::ScopeListable)
             .where(visible: true)
             .order(:name)
             .select("tags.*, (select exists (select id from user_hidden_items where user_hideable_type='Tag' and user_hideable_id = tags.id and user_id = #{Current.user.id})) as user_hidden")
  end

  def set_filter_items
    @items = policy_scope(Filter, policy_scope_class: FilterPolicy::ScopeShowable)
             .order(:position)
             .select("filters.*, (select exists (select id from user_hidden_items where user_hideable_type='Filter' and user_hideable_id = filters.id and user_id = #{Current.user.id})) as user_hidden")
  end

  def set_user_hidden_item
    @user_hidden_item = policy_scope(UserHiddenItem).find(params[:id])
  end

  def user_hidden_item_params
    params.require(:user_hidden_item).permit(:user_hideable_type, :user_hideable_id)
  end
end
