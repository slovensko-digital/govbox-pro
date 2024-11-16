# == Schema Information
#
# Table name: tag_groups
#
#  id         :integer          not null, primary key
#  group_id   :integer          not null
#  tag_id     :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TagGroup < ApplicationRecord
  include AuditableEvents

  belongs_to :group
  belongs_to :tag, counter_cache: true

  # used for joins only
  has_many :group_memberships, primary_key: :group_id, foreign_key: :group_id
end
