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

  validates_presence_of :name, :email
  validates_uniqueness_of :name, :email, scope: :tenant_id

  before_destroy :delete_user_group, prepend: true
  after_create :handle_default_groups

  def site_admin?
    ENV['SITE_ADMIN_EMAILS'].to_s.split(',').include?(email)
  end

  def admin?
    groups.exists?(group_type: 'ADMIN')
  end

  private

  def delete_user_group
    groups.destroy_by(group_type: 'USER')
  end

  def handle_default_groups
    groups.create!(name: name, group_type: 'USER', tenant_id: tenant_id)
    group_memberships.create!(group: tenant.all_group)
  end
end
