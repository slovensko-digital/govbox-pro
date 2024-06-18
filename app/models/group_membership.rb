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

  after_create :create_signing_tags!, if: ->(membership) { membership.group.is_a?(SignerGroup) }
  after_destroy :destroy_all_signature_requests!, if: ->(membership) { membership.group.is_a?(SignerGroup) }

  def create_signing_tags!
    user_group = user.user_group
    tenant = group.tenant

    find_or_create_signing_tag(
      tags_scope: tenant.signature_requested_from_tags,
      user_group: user_group,
      tag_name: "Na podpis: #{user.name}",
      color: "yellow",
      icon: "pencil"
    )

    find_or_create_signing_tag(
      tags_scope: tenant.signed_by_tags,
      user_group: user_group,
      tag_name: "Podpísané: #{user.name}",
      color: "green",
      icon: "fingerprint"
    )
  end

  def destroy_all_signature_requests!
    tag = group.tenant.signature_requested_from_tags.find_tag_containing_group(user.user_group)
    tag.destroy if tag
  end


  def find_or_create_signing_tag(tags_scope:, user_group:, tag_name:, color:, icon:)
    tag = tags_scope.find_tag_containing_group(user_group) || tags_scope.find_or_initialize_by(
      name: tag_name
    )

    tag.name = tag_name
    tag.visible = true
    tag.groups = [user_group]
    tag.color = color
    tag.icon = icon
    tag.save!
  end
end
