class Api::TagsController < Api::TenantController
  def create
    @thread = @tenant.message_threads.find(params[:message_thread_id])
    @tags = tag_params
    @tags.each do |tag_name|
      tag = @tenant.tags.find_by(name: tag_name)
      tag ||= @tenant.simple_tags.create!(name: tag_name)
      @thread.tags << tag if tag && @thread.tags.exclude?(tag)
    end
  end

  def destroy
    @thread = @tenant.message_threads.find(params[:message_thread_id])
    @tags = tag_params
    @tags.each do |tag_name|
      tag = @thread.tags.find_by(name: tag_name)
      @thread.tags.delete(tag) if tag
    end
  end

  def tag_params
    params.require(:tags)
  end
end
