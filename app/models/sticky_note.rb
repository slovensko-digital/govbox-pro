# == Schema Information
#
# Table name: sticky_notes
#
#  id         :bigint           not null, primary key
#  data       :jsonb
#  note_type  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
class StickyNote < ApplicationRecord
  belongs_to :user
end
