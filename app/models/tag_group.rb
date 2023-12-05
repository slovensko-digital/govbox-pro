# == Schema Information
#
# Table name: tag_groups
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  group_id   :bigint           not null
#  tag_id     :bigint           not null
#
class TagGroup < ApplicationRecord
  include AuditableEvents

  belongs_to :group
  belongs_to :tag

  # used for joins only
  has_many :group_memberships, primary_key: :group_id, foreign_key: :group_id
end
