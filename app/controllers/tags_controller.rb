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
    @tags = @tenant.tags
                   .where.not(id: @object.tags.ids)
                   .where(visible: true)
    @tags = @tags.where('unaccent(name) ILIKE unaccent(?)', "%#{params[:name_search]}%") if params[:name_search]
  end

  def create
    @tag = Current.tenant.tags.new(tag_params)
    @tag.user_id = Current.user.id
    @tag.groups << Group.find_by(name: Current.user.name, tenant_id: Current.tenant.id, group_type: 'USER')
    authorize @tag

    if @tag.save
      redirect_back fallback_location: "/message_threads", notice: 'Tag was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_object
    klass = params[:object_class]
    @object = policy_scope(class_eval(klass)).find(params[:object_id]) if klass.in? %w[Message MessageThread]
  end

  def tag_params
    params.require(:tag).permit(:name, message_threads_tags_attributes: [:message_thread_id], messages_tags_attributes: [:message_id])
  end

  def set_visible_tags
    @visible_tags = policy_scope(Tag).where(visible: true)
  end

  def set_tag
    @tag = policy_scope(Tag).find(params[:id])
  end
end
