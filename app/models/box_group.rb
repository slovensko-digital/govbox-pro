# frozen_string_literal: true

# == Schema Information
#
# Table name: box_groups
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  box_id     :bigint           not null
#  group_id   :bigint           not null
#
class BoxGroup < ApplicationRecord
  include AuditableEvents

  belongs_to :box
  belongs_to :group

  # used for joins only
  has_many :group_memberships, primary_key: :group_id, foreign_key: :group_id
end
