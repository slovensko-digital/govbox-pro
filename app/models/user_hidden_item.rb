# == Schema Information
#
# Table name: user_hidden_items
#
#  id                 :bigint           not null, primary key
#  user_hideable_type :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_hideable_id   :bigint
#  user_id            :bigint           not null
#
class UserHiddenItem < ApplicationRecord
  belongs_to :user
  belongs_to :user_hideable, polymorphic: true
end
