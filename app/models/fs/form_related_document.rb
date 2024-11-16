# == Schema Information
#
# Table name: fs_form_related_documents
#
#  id            :integer          not null, primary key
#  fs_form_id    :integer          not null
#  data          :string           not null
#  language      :string           not null
#  document_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Fs::FormRelatedDocument < ApplicationRecord
  belongs_to :form, class_name: 'Fs::Form', foreign_key: 'fs_form_id'
end
