# == Schema Information
#
# Table name: message_thread_merge_identifiers
#
#  id                                          :integer          not null, primary key
#  message_thread_id                           :integer          not null
#  tenant_id                                   :integer          not null
#  uuid                                        :uuid             not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class MessageThreadMergeIdentifier < ApplicationRecord
  belongs_to :message_thread
  belongs_to :tenant
end
