# == Schema Information
#
# Table name: group_memberships
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  group_id   :bigint           not null
#  user_id    :bigint           not null
#
class GroupMembership < ApplicationRecord
  include AuditableEvents

  belongs_to :group
  belongs_to :user

  after_create do |group_membership|
    if group_membership.group.is_a?(SignerGroup)
      self.class.create_signing_tags_for(group_membership)
    end
  end

  after_destroy do |group_membership|
    if group_membership.group.is_a?(SignerGroup)
      self.class.destroy_all_signature_requests_for(group_membership)
    end
  end

  def self.create_signing_tags_for(group_membership)
    user = group_membership.user
    user_group = user.user_group
    tenant = group_membership.group.tenant

    find_or_create_signing_tag(
      tags_scope: tenant.signature_requested_from_tags,
      user_group: user_group,
      tag_name: "Na podpis - #{user.name}"
    )

    find_or_create_signing_tag(
      tags_scope: tenant.signed_by_tags,
      user_group: user_group,
      tag_name: "Podpisané - #{user.name}"
    )
  end

  def self.destroy_all_signature_requests_for(group_membership)
    tag = group_membership.group.tenant.signature_requested_from_tags.find_tag_containing_group(group_membership.user.user_group)
    tag.destroy if tag
  end

  def self.find_or_create_signing_tag(tags_scope:, user_group:, tag_name:)
    tag = tags_scope.find_tag_containing_group(user_group) || tags_scope.find_or_initialize_by(
      name: tag_name
    )

    tag.name = tag_name
    tag.visible = true
    tag.groups = [user_group]
    tag.save!
  end
end
