# == Schema Information
#
# Table name: boxes
#
#  id                                          :integer          not null, primary key
#  tenant_id                                   :integer          not null
#  name                                        :string           not null
#  uri                                         :string
#  syncable                                    :boolean          not null, default: true
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Box < ApplicationRecord
  belongs_to :tenant

  has_many :folders
  has_many :message_threads, through: :folders, extend: MessageThreadsExtensions
  has_many :message_drafts_imports

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
end
