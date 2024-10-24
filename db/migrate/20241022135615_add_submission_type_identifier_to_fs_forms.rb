class AddSubmissionTypeIdentifierToFsForms < ActiveRecord::Migration[7.1]
  def change
    add_column :fs_forms, :submission_type_identifier, :string
  end
end
