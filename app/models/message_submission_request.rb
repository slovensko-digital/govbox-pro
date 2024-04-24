# == Schema Information
#
# Table name: message_submission_requests
#
#  id              :bigint           not null, primary key
#  request_url     :string
#  response_status :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  box_id          :bigint           not null
#
class MessageSubmissionRequest < ApplicationRecord
  scope :billable, -> { where(response_status: 200) }
  scope :requested_between, -> (from, to) { where(created_at: from..to) }
end
