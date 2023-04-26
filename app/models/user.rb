# == Schema Information
#
# Table name: users
#
#  id                                          :integer          not null, primary key
#  email                                       :string           not null
#  name                                        :string           not null
#  tenant_id                                   :integer
#  role                                        :integer          default("regular"), not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class User < ApplicationRecord
  enum role: { regular: 0, admin: 1, super_admin: 2 }

  belongs_to :tenant

  def logged_in?
    true
  end
end
