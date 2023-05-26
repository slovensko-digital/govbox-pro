# == Schema Information
#
# Table name: users
#
#  id                                          :integer          not null, primary key
#  email                                       :string           not null
#  name                                        :string           not null
#  tenant_id                                   :integer
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class User < ApplicationRecord
  belongs_to :tenant
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships

  before_destroy :delete_special_group, prepend: true
  after_create :handle_default_groups

  def site_admin?
    user_type == 'SITE_ADMIN'
  end

  def admin?
    groups.exists?(group_type: 'ADMIN')
  end

  private

  def delete_special_group
    groups.destroy_by(group_type: 'USER')
  end

  def handle_default_groups
    groups.create!(name: name , group_type: 'USER', tenant_id: tenant_id)
    group_memberships.create!(group_id: Group.find_by(tenant_id: tenant_id, group_type: 'ALL').id)
  end
end
