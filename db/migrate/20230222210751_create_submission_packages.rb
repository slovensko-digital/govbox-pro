class CreateSubmissionPackages < ActiveRecord::Migration[7.0]
  def change
    create_table :submissions_packages do |t|
      t.string :name, null: false
      t.integer :status, default: 0
      t.string :content_path
      t.references :subject, null: false, foreign_key: true

      t.timestamps
    end
  end
end
