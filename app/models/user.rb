# == Schema Information
#
# Table name: users
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :bigint
#
class User < ApplicationRecord
  belongs_to :tenant

  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :own_tags, class_name: 'Tag', foreign_key: 'user_id', inverse_of: :owner, dependent: :nullify
  has_many :message_drafts, foreign_key: :author_id
  has_many :automation_rules, class_name: 'Automation::Rule'
  has_many :filters, foreign_key: :author_id

  validates_presence_of :name, :email
  validates_uniqueness_of :name, :email, scope: :tenant_id, case_sensitive: false

  before_destroy :delete_user_group, prepend: true
  after_create :handle_default_groups

  def site_admin?
    ENV['SITE_ADMIN_EMAILS'].to_s.split(',').include?(email)
  end

  def admin?
    groups.exists?(type: "AdminGroup")
  end

  def user_group
    groups.where(type: "UserGroup").first
  end

  private

  def delete_user_group
    user_group.destroy
  end

  def handle_default_groups
    groups.create!(name: name, type: "UserGroup", tenant_id: tenant_id)
    group_memberships.create!(group: tenant.all_group)
  end
end
