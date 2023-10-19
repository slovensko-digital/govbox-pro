# == Schema Information
#
# Table name: upvs_box_api_connections
#
#  id                                          :integer          not null, primary key
#  box_id                                      :integer          not null
#  api_connection_id                           :integer          not null
#  obo                                         :uuid
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Upvs::BoxApiConnection < ApplicationRecord
  belongs_to :box
  belongs_to :api_connection, class_name: 'Upvs::ApiConnection'

  validates :obo, absence: true, if: -> { api_connection.is_a?(::Govbox::ApiConnection) }
end
