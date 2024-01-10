class AssignSignedExternallyTagToMessageObjects < ActiveRecord::Migration[7.1]
  def up
    Tenant.includes(:signed_externally_tag).find_each do |tenant|
      MessageObject.joins(message: { thread: :box }).
        where(boxes: { tenant_id: tenant }, is_signed: true).
        find_each { |message_object|
          message_object.message_objects_tags.find_or_create_by!(tag: tenant.signed_externally_tag!)
        }
    end
  end

  def down
    Tenant.includes(:signed_externally_tag).find_each do |tenant|
      MessageObjectsTag.where(tag_id: tenant.signed_externally_tag!).destroy_all
    end
  end
end
