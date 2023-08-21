class TagGroup < ApplicationRecord
  belongs_to :group
  belongs_to :tag

  # used for joins only
  has_many :group_memberships, primary_key: :group_id, foreign_key: :group_id
end
