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

  before_destroy :validate_self_admin_removal, prepend: true

  private

  def validate_self_admin_removal
    return unless group.type == 'AdminGroup' && user == Current.user

    errors.add :base, "Administrátor nemôže odobrať administrátorské práva sám sebe"
    throw :abort
  end
end
