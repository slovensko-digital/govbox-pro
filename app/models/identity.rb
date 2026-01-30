# == Schema Information
#
# Table name: identities
#
#  id              :bigint           not null, primary key
#  email           :string           not null
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :bigint           not null
#
class Identity < OmniAuth::Identity::Models::ActiveRecord
  auth_key :email

  belongs_to :user, optional: true

  validates :email, presence: true, uniqueness: true
end
