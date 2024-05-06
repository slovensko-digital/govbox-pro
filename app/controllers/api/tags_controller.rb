class Api::TagsController < Api::TenantController
  def create
    @thread = @tenant.message_threads.find(params[:message_thread_id])
    @tag = @tenant.tags.find_by(name: tag_params)
    raise ActiveRecord::RecordNotFound unless @tag

    @thread.tags << @tag if @thread.tags.exclude?(@tag)
  end

  def destroy
    @thread = @tenant.message_threads.find(params[:message_thread_id])
    @tag = @tenant.tags.find_by(name: tag_params)
    @thread.tags.delete(@tag)
  end

  def batch_add
    @thread = @tenant.message_threads.find(params[:message_thread_id])
    @tags = tag_batch_params
    @result = []
    @tags.each do |tag_name|
      tag = @tenant.tags.find_by(name: tag_name)
      @result << { tag_name => "added" } if tag && @thread.tags.exclude?(tag)
      @result << { tag_name => "not_found" } unless tag
      @result << { tag_name => "skipped" } if tag && @thread.tags.include?(tag)
      @thread.tags << tag if tag && @thread.tags.exclude?(tag)
    end
  end

  def batch_remove
    @thread = @tenant.message_threads.find(params[:message_thread_id])
    @tags = tag_batch_params
    @result = []
    @tags.each do |tag_name|
      tag = @thread.tags.find_by(name: tag_name)
      @result << { tag_name => "removed" } if tag
      @result << { tag_name => "skipped" } unless tag
      @thread.tags.delete(tag) if tag
    end
  end

  def tag_batch_params
    params.require(:tags)
  end

  def tag_params
    params.require(:tag).require(:name)
  end
end
