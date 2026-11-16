# frozen_string_literal: true

class AddSkippedPdfPathsToExports < ActiveRecord::Migration[8.1]
  def change
    add_column :exports, :skipped_pdf_paths, :string, array: true, default: [], null: false
  end
end
