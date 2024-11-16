# == Schema Information
#
# Table name: upvs_form_related_documents
#
#  id            :integer          not null, primary key
#  upvs_form_id  :integer          not null
#  data          :string           not null
#  language      :string           not null
#  document_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Upvs::FormRelatedDocument < ApplicationRecord
  belongs_to :form, class_name: 'Upvs::Form', foreign_key: 'upvs_form_id'
end
