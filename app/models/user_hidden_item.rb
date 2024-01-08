class UserHiddenItem < ApplicationRecord
  belongs_to :user
  belongs_to :user_hideable, polymorphic: true
end
