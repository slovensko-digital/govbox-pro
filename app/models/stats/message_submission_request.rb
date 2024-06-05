# == Schema Information
#
# Table name: stats_message_submission_requests
#
#  id              :bigint           not null, primary key
#  bulk            :boolean
#  request_url     :string
#  response_status :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  box_id          :bigint           not null
#
class Stats::MessageSubmissionRequest < ApplicationRecord
  scope :requested_between, -> (from, to) { where(created_at: from..to) }
end
