# == Schema Information
#
# Table name: message_objects_tags
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  message_object_id :bigint           not null
#  tag_id            :bigint           not null
#
require "test_helper"

class MessageObjectsTagTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
