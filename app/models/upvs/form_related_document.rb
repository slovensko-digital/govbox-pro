# == Schema Information
#
# Table name: upvs_form_related_documents
#
#  id            :bigint           not null, primary key
#  data          :string           not null
#  document_type :string           not null
#  language      :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  upvs_form_id  :bigint           not null
#
class Upvs::FormRelatedDocument < ApplicationRecord
  belongs_to :form, class_name: 'Upvs::Form', foreign_key: 'upvs_form_id'
end
