# == Schema Information
#
# Table name: users
#
#  id                           :integer          not null, primary key
#  tenant_id                    :integer
#  email                        :string           not null
#  name                         :string           not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  saml_identifier              :string
#  notifications_last_opened_at :datetime
#  notifications_reset_at       :datetime
#

class User < ApplicationRecord
  include AuditableEvents

  belongs_to :tenant

  has_one :draft_tag, foreign_key: :owner_id
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :own_tags, class_name: 'Tag', inverse_of: :owner, foreign_key: :owner_id, dependent: :nullify
  has_many :message_drafts, foreign_key: :author_id
  has_many :automation_rules, class_name: 'Automation::Rule'
  has_many :filters, foreign_key: :author_id
  has_many :filter_subscriptions
  has_many :notifications

  validates_presence_of :name, :email
  validates_uniqueness_of :name, :email, scope: :tenant_id, case_sensitive: false

  before_destroy :delete_user_group, prepend: true
  after_create :handle_default_settings

  def site_admin?
    ENV['SITE_ADMIN_EMAILS'].to_s.split(',').include?(email)
  end

  def admin?
    groups.exists?(type: "AdminGroup")
  end

  def user_group
    groups.where(type: "UserGroup").first
  end

  def accessible_tags
    Tag.where(
      TagGroup.select(1)
              .joins(:group_memberships)
              .where("tag_groups.tag_id = tags.id")
              .where(group_memberships: { user_id: id })
              .arel.exists
    )
  end

  def signer?
    groups.exists?(id: tenant.signer_group)
  end

  def signed_by_tag
    tenant.signed_by_tags.find_tag_containing_group(user_group)
  end

  def signature_requested_from_tag
    tenant.signature_requested_from_tags.find_tag_containing_group(user_group)
  end

  def update_notifications_retention
    if notifications_reset_at.blank?
      update(notifications_reset_at: 5.minutes.from_now)
    elsif notifications_reset_at < Time.current
      update(
        notifications_last_opened_at: notifications_reset_at,
        notifications_reset_at: 5.minutes.from_now
      )
    end
  end

  private

  def delete_user_group
    user_group.destroy
  end

  def handle_default_settings
    user_group = groups.create!(name: name, type: "UserGroup", tenant_id: tenant_id)
    group_memberships.create!(group: tenant.all_group)

    draft_tag = tenant.tags.create(
      owner: self,
      name: "Drafts-#{name}",
      type: "DraftTag",
      visible: false
    )
    draft_tag.mark_readable_by_groups([user_group])
  end
end
