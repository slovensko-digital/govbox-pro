# == Schema Information
#
# Table name: boxes
#
#  id                                          :integer          not null, primary key
#  tenant_id                                   :integer          not null
#  name                                        :string           not null
#  uri                                         :string
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Box < ApplicationRecord
  belongs_to :tenant

  has_many :folders, dependent: :destroy
  has_many :message_threads, through: :folders, extend: MessageThreadsExtensions, dependent: :destroy
  has_many :message_drafts_imports, dependent: :destroy

  before_destroy { Govbox::ApiConnection.find_by(box_id: id).destroy }
end

