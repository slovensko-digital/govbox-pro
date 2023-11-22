# == Schema Information
#
# Table name: message_thread_merge_identifiers
#
#  id                :bigint           not null, primary key
#  uuid              :uuid             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  box_id            :bigint           not null
#  message_thread_id :bigint           not null
#
class MessageThreadMergeIdentifier < ApplicationRecord
  belongs_to :message_thread
  belongs_to :box
end
