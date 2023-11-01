# == Schema Information
#
# Table name: nested_message_objects
#
#  id                                          :integer          not null, primary key
#  name                                        :string
#  mimetype                                    :string
#  content                                     :binary           not null
#  message_object_id                           :integer          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class NestedMessageObject < ApplicationRecord
  belongs_to :message_object

  validates :name, presence: true, on: :validate_data
  validate :allowed_mime_type?, on: :validate_data

  def self.create_from_message_object(message_object)
    return unless message_object.asice?

    nested_message_objects = SignedAttachment::Asice.extract_documents_from_content(message_object.content)

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
