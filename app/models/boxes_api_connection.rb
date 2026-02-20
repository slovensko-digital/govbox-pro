# == Schema Information
#
# Table name: boxes_api_connections
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE), not null
#  settings          :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  api_connection_id :bigint           not null
#  box_id            :bigint           not null
#
class BoxesApiConnection < ApplicationRecord
  belongs_to :box
  belongs_to :api_connection

  store_accessor :settings, :delegate_id, prefix: true

  scope :active, -> { where(active: true) }

  after_create :add_owner_access_rights_to_box
  after_commit :update_box_active_state, on: [:create, :update, :destroy]

  private

  def update_box_active_state
    return unless box
    return if box.destroyed? || box.frozen?

    box.update_active_state_from_connections
  end

  private

  def add_owner_access_rights_to_box
    owner = api_connection.owner
    return unless owner

    box.box_groups.find_or_create_by!(group: owner.user_group)
  end
end
