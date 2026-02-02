# == Schema Information
#
# Table name: boxes
#
#  id          :bigint           not null, primary key
#  color       :enum
#  export_name :string           not null
#  active      :boolean          default(TRUE), not null
#  name        :string           not null
#  settings    :jsonb            not null
#  short_name  :string
#  syncable    :boolean          default(TRUE), not null
#  type        :string
#  uri         :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  tenant_id   :bigint           not null
#
class Box < ApplicationRecord
  include Colorized

  belongs_to :tenant
  has_many :boxes_api_connections
  has_many :api_connections, through: :boxes_api_connections
  has_many :box_groups, dependent: :destroy
  has_many :groups, through: :box_groups
  has_many :message_threads, extend: MessageThreadsExtensions, dependent: :destroy
  has_many :messages, through: :message_threads
  has_many :message_submission_requests, dependent: :destroy, class_name: '::Stats::MessageSubmissionRequest'
  has_many :message_drafts_imports, dependent: :destroy
  has_many :automation_conditions, as: :condition_object

  scope :active, -> { where(active: true) }
  scope :syncable, -> { where(syncable: true) }
  scope :with_enabled_message_drafts_import, -> { active.where("(settings ->> 'message_drafts_import_enabled')::boolean = ?", true) }

  before_destroy do |box|
    api_connection.destroy if api_connection.destroy_with_box?(self)
    boxes_api_connections.destroy_all
    EventBus.publish(:box_destroyed, box.id)
  end

  before_create { self.color = Box.colors.keys[name.hash % Box.colors.size] if color.blank? }

  validates_presence_of :name, :short_name, :uri, :export_name
  
  before_validation :set_default_export_name, on: :create
  validate :validate_api_connection_presence
  validate :validate_box_with_api_connections

  def self.create_with_api_connection!(params)
    raise NotImplementedError
  end

  def api_connection
    api_connections.first
  end

  def sync
    raise NotImplementedError
  end

  def self.sync_all
    active.syncable.find_each(&:sync)
  end

  def single_recipient?
    raise NotImplementedError
  end

  def update_active_state_from_connections
    new_active_state = boxes_api_connections.active.exists?
    update_columns(active: new_active_state) if !destroyed? && !frozen? && active != new_active_state
  end

  def official_name
    name.match(/^FS (.*?)(?:\s*(v zastúpení:.*| \(oblasť SPD\)))?$/)&.captures&.first || name
  end

  private

  def set_default_export_name
    self.export_name = official_name if export_name.blank?
  end

  def validate_api_connection_presence
    errors.add(:api_connection, :blank) if api_connections.empty?
  end

  def validate_box_with_api_connections
    api_connections.each do |api_connection|
      errors.add(:api_connection, :invalid) if api_connection.tenant && (api_connection.tenant.id != tenant.id)
      api_connection.validate_box(self)
    end
  end
end
