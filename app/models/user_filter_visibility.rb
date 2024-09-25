# == Schema Information
#
# Table name: user_filter_visibilities
#
#  id         :bigint           not null, primary key
#  position   :integer
#  visible    :boolean          default(TRUE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  filter_id  :bigint           not null
#  user_id    :bigint           not null
#
class UserFilterVisibility < ApplicationRecord
  belongs_to :user
  belongs_to :filter

  acts_as_list scope: :user_id

  def hidden
    !visible
  end
end
