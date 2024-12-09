# == Schema Information
#
# Table name: message_object_data
#
#  id                :bigint           not null, primary key
#  blob              :binary           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_object_id :bigint           not null
#
require "test_helper"

class MessageObjectDatumTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
