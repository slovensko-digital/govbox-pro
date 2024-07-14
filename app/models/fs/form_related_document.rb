# == Schema Information
#
# Table name: fs_form_related_documents
#
#  id            :bigint           not null, primary key
#  data          :string           not null
#  document_type :string           not null
#  language      :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  fs_form_id    :bigint           not null
#
class Fs::FormRelatedDocument < ApplicationRecord
  belongs_to :form, class_name: 'Fs::Form', foreign_key: 'fs_form_id'
end
