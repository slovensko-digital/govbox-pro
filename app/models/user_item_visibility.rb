# == Schema Information
#
# Table name: user_item_visibilities
#
#  id             :bigint           not null, primary key
#  position       :integer
#  user_item_type :string           not null
#  visible        :boolean          default(TRUE), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint           not null
#  user_item_id   :bigint
#
class UserItemVisibility < ApplicationRecord
  belongs_to :user
  belongs_to :user_item, polymorphic: true

  acts_as_list scope: [:user_id, :user_item_type]

  def hidden
    !visible
  end
end
