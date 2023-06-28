class TagUser < ApplicationRecord
  belongs_to :tag
  belongs_to :user
end
