class CreateSubmissionPackages < ActiveRecord::Migration[6.1]
  def change
    create_table 'submission.packages' do |t|
      t.string :name, null: false
      t.binary :content
      t.integer :status, default: 0
      t.references :subject, null: false, foreign_key: true

      t.timestamps
    end
  end
end
