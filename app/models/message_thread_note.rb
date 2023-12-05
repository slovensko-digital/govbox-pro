# == Schema Information
#
# Table name: message_thread_notes
#
#  id                :bigint           not null, primary key
#  note              :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_thread_id :bigint           not null
#
class MessageThreadNote < ApplicationRecord
  include AuditableEvents

  belongs_to :message_thread
end
