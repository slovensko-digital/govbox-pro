# == Schema Information
#
# Table name: nested_message_objects
#
#  id                :bigint           not null, primary key
#  content           :binary           not null
#  mimetype          :string
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_object_id :bigint           not null
#
class NestedMessageObject < ApplicationRecord
  belongs_to :message_object, inverse_of: :nested_message_objects

  validates :name, presence: true, on: :validate_data
  validate :allowed_mime_type?, on: :validate_data

  def self.create_from_message_object(message_object)
    return unless message_object.asice?

    nested_message_objects = SignedAttachment::Asice.extract_documents_from_content(message_object.content)
    message_object.nested_message_objects.destroy_all

    nested_message_objects.each do |nested_message_object|
      message_object.nested_message_objects.create!(
        name: nested_message_object.name,
        mimetype: nested_message_object.mimetype,
        content: nested_message_object.content
      )
    end
  end

  def xml?
    mimetype == 'application/xml'
  end
end
