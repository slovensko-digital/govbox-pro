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
#  uri               :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  api_connection_id :bigint
#  tenant_id         :bigint           not null
#
class Box < ApplicationRecord
  belongs_to :tenant
  belongs_to :api_connection

  has_many :folders, class_name: "Govbox::Folder"
  has_many :message_threads, extend: MessageThreadsExtensions, dependent: :destroy
  has_many :messages, through: :message_threads
  has_many :message_drafts_imports, dependent: :destroy
  has_many :automation_conditions, as: :condition_object

  after_destroy do |box|
    api_connection.destroy if api_connection.destroy_with_box?
    EventBus.publish(:box_destroyed, box.id)
  end

  before_create { self.color = Box.colors.keys[name.hash % Box.colors.size] if color.blank? }

  enum :color,
       {
         slate: 'slate',
         gray: 'gray',
         zinc: 'zinc',
         neutral: 'neutral',
         stone: 'stone',
         red: 'red',
         orange: 'orange',
         amber: 'amber',
         yellow: 'yellow',
         lime: 'lime',
         green: 'green',
         emerald: 'emerald',
         teal: 'teal',
         cyan: 'cyan',
         sky: 'sky',
         blue: 'blue',
         indigo: 'indigo',
         violet: 'violet',
         purple: 'purple',
         fuchsia: 'fuchsia',
         pink: 'pink',
         rose: 'rose'
       }

  validate :validate_box_with_api_connection

  private

  def validate_box_with_api_connection
    api_connection.validate_box(self)
  end
end
