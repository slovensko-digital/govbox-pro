# == Schema Information
#
# Table name: message_thread_notes
#
#  id                :integer          not null, primary key
#  message_thread_id :integer          not null
#  note              :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class MessageThreadNote < ApplicationRecord
  include AuditableEvents

  belongs_to :message_thread, touch: true
end
