class TagsController < ApplicationController
  before_action :set_tag, only: %i[show]
  before_action :set_visible_tags

  def show
    authorize [:admin, @tag]
  end

  def get_available
    authorize [Tag]
    set_object
    @tenant = Current.tenant
    @tags =
      @tenant.tags.where.not(id: @object.tags.ids).where(visible: true)
                  .where(id: TagGroup.select(:tag_id).joins(:group, :tag, group: :users).where(group: { tenant_id: @tenant.id }, tag: { tenant_id: @tenant.id }, users: { id: Current.user.id }))
    respond_to { |format| format.html }
  end

  private

  def set_object
    @object = policy_scope(Message).find(params[:object_id]) if params[:object_class] == 'Message'
    @object = policy_scope(MessageThread).find(params[:object_id]) if params[:object_class] == 'MessageThread'
  end

  def set_visible_tags
    @visible_tags = policy_scope(Tag).where(visible: true)
  end

  def set_tag
    @tag = policy_scope(Tag).find(params[:id])
  end
end
