# == Schema Information
#
# Table name: boxes
#
#  id                :bigint           not null, primary key
#  color             :enum
#  name              :string           not null
#  settings          :jsonb
#  short_name        :string
#  syncable          :boolean          default(TRUE), not null
#  type              :string
#  uri               :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  api_connection_id :bigint
#  tenant_id         :bigint           not null
#
class Box < ApplicationRecord
  include Colorized

  belongs_to :tenant
  belongs_to :api_connection
  has_many :boxes_other_api_connections, dependent: :destroy
  has_many :other_api_connections, through: :boxes_other_api_connections, class_name: 'ApiConnection', source: :api_connection

  has_many :message_threads, extend: MessageThreadsExtensions, dependent: :destroy
  has_many :messages, through: :message_threads
  has_many :message_submission_requests, dependent: :destroy, class_name: '::Stats::MessageSubmissionRequest'
  has_many :message_drafts_imports, dependent: :destroy
  has_many :automation_conditions, as: :condition_object

  scope :with_enabled_message_drafts_import, -> { where("(settings ->> 'message_drafts_import_enabled')::boolean = ?", true) }

  after_destroy do |box|
    api_connection.destroy if api_connection.destroy_with_box?
    EventBus.publish(:box_destroyed, box.id)
  end

  before_create { self.color = Box.colors.keys[name.hash % Box.colors.size] if color.blank? }

  validates_presence_of :name, :short_name, :uri
  validate :validate_box_with_api_connection

  def self.create_with_api_connection!(params)
    raise NotImplementedError
  end

  def sync
    raise NotImplementedError
  end

  def self.sync_all
    find_each(&:sync)
  end

  def single_recipient?
    raise NotImplementedError
  end

  def official_name
    name.match(/^FS (.*?)(?:\s*(v zastúpení:.*| \(oblasť SPD\)))?$/)&.captures&.first || name
  end

  private

  def validate_box_with_api_connection
    errors.add(:api_connection, :invalid) if api_connection.tenant && (api_connection.tenant.id != tenant.id)

    api_connection.validate_box(self)
  end
end
