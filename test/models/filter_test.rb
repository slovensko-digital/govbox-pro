# == Schema Information
#
# Table name: filters
#
#  id         :bigint           not null, primary key
#  is_pinned  :boolean          default(FALSE), not null
#  name       :string           not null
#  position   :integer          not null
#  query      :string
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  author_id  :bigint           not null
#  tag_id     :bigint
#  tenant_id  :bigint           not null
#
require "test_helper"

class FilterTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
