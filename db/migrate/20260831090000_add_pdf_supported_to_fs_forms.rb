# frozen_string_literal: true

class AddPdfSupportedToFsForms < ActiveRecord::Migration[7.1]
  def change
    add_column :fs_forms, :pdf_supported, :boolean, default: false, null: false
  end
end
