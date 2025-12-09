# == Schema Information
#
# Table name: boxes_api_connections
#
#  id                :bigint           not null, primary key
#  settings          :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  api_connection_id :bigint           not null
#  box_id            :bigint           not null
#
class BoxesApiConnection < ApplicationRecord
  belongs_to :box
  belongs_to :api_connection

  store_accessor :settings, :delegate_id, :active, prefix: true

  scope :active, -> { where("(settings ->> 'active')::boolean IS NULL OR (settings ->> 'active')::boolean = ?", true) }

  before_validation :set_default_active, on: :create
  after_commit :update_box_active_state, on: [:create, :update, :destroy]

  def active?
    return true if settings_active.nil?

    ActiveRecord::Type::Boolean.new.cast(settings_active)
  end

  private

  def set_default_active
    self.settings_active = true if settings_active.nil?
  end

  def update_box_active_state
    return unless box
    return if box.destroyed? || box.frozen?

    box.update_active_state_from_connections
  end
end
