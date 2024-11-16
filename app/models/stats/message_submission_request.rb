# == Schema Information
#
# Table name: stats_message_submission_requests
#
#  id              :integer          not null, primary key
#  box_id          :integer          not null
#  request_url     :string
#  response_status :integer
#  bulk            :boolean
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Stats::MessageSubmissionRequest < ApplicationRecord
  scope :requested_between, -> (from, to) { where(created_at: from..to) }
end
