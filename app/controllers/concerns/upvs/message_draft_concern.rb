module Upvs::MessageDraftConcern
  def create_upvs_message_draft
    set_box
    render_unprocessable_entity('Invalid Sender Uri') and return unless @box

    ::Upvs::MessageDraft.transaction do
      @message = ::Upvs::MessageDraft.create(message_params)
      @message.thread = @box&.message_threads&.find_or_build_by_merge_uuid(
        box: @box,
        merge_uuid: @message.metadata['correlation_id'],
        title: @message.title,
        delivered_at: @message.delivered_at
      )

      render_unprocessable_entity(@message.errors.messages.values.join(', ')) and return unless @message.valid?
      @message.save

      permitted_params.fetch(:objects, []).each do |object_params|
        message_object = @message.objects.create(object_params.except(:content))
        object_tags = message_object.is_signed ? [@message.thread.box.tenant.signed_externally_tag!] : []

        message_object.tags += object_tags

        MessageObjectDatum.create(
          message_object: message_object,
          blob: Base64.decode64(object_params[:content])
        )
      end

      permitted_params.fetch(:tags, []).each do |tag_name|
        tag = @tenant.tags.find_by(name: tag_name)

        unless tag
          @message.destroy
          render_unprocessable_entity("Tag with name #{tag_name} does not exist") and return
        end

        @message.add_cascading_tag(tag)
      end

      if @message.valid?(:validate_data)
        @message.metadata['status'] = 'created'
        @message.save

        head :created
      else
        @message.destroy

        render_unprocessable_entity(@message.errors.messages.values.join(', '))
      end
    end
  end

  private

  def set_box
    @box = @tenant.boxes.find_by(uri: permitted_params[:sender_uri])
  end

  def message_params
    permitted_message_params = permitted_params
    {
      delivered_at: Time.now,
      outbox: true,
      # recipient_name: TODO search name in UPVS dataset,
      replyable: false,
      sender_name: @box.name,
      title: permitted_message_params['title'],
      uuid: permitted_message_params['message_id'],
      metadata: {
        correlation_id: permitted_message_params['correlation_id'],
        reference_id: permitted_message_params['reference_id'],
        sender_uri: permitted_message_params['sender_uri'],
        recipient_uri: permitted_message_params['recipient_uri'],
        sender_business_reference: permitted_message_params['sender_business_reference'],
        recipient_business_reference: permitted_message_params['recipient_business_reference'],
        posp_id: permitted_message_params['posp_id'],
        posp_version: permitted_message_params['posp_version'],
        message_type: permitted_message_params['message_type'],
        status: 'being_loaded'
      }
    }
  end

  def permitted_params
    params.permit(
      :type,
      :message_id,
      :correlation_id,
      :reference_id,
      :sender_uri,
      :recipient_uri,
      :sender_business_reference,
      :recipient_business_reference,
      :posp_id,
      :posp_version,
      :message_type,
      :title,
      objects: [
        :name,
        :is_signed,
        :to_be_signed,
        :mimetype,
        :object_type,
        :content,
      ],
      tags: []
    )
  end
end
