class FillMessageRelations < ActiveRecord::Migration[7.0]
  def up
    Message.find_each do |message|
      relation_type = nil

      case message.metadata['edesk_class']
      when 'ED_DELIVERY_NOTIFICATION'
        relation_type = 'delivery_notification'
      when 'ED_DELIVERY_REPORT'
        relation_type = 'delivery_report'
      when 'POSTING_CONFIRMATION', 'POSTING_INFORMATION'
        relation_type = 'posting_confirmation'
      else
        # noop
      end

      if relation_type
        major_message = Message.find_by(uuid: message.metadata["reference_id"])

      if major_message
        major_message.message_relations.find_or_create_by(
          related_message: message,
          relation_type: relation_type
        )
      end
      end
    end
  end
end
