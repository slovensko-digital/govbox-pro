# == Schema Information
#
# Table name: boxes_other_api_connections
#
#  id                :bigint           not null, primary key
#  settings          :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  api_connection_id :bigint           not null
#  box_id            :bigint           not null
#
class BoxesOtherApiConnection < ApplicationRecord
  belongs_to :box
  belongs_to :api_connection
end
