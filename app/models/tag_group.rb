# == Schema Information
#
# Table name: tag_groups
#
#  tag_id                                      :integer          not null
#  group_id                                    :integer          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class TagGroup < ApplicationRecord
  belongs_to :group
  belongs_to :tag

  # used for joins only
  has_many :group_memberships, primary_key: :group_id, foreign_key: :group_id
end
