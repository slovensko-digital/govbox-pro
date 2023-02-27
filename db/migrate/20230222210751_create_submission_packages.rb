class CreateSubmissionPackages < ActiveRecord::Migration[6.1]
  def change
    create_table 'submission.packages' do |t|
      t.string :name, null: false
      t.binary :content, null: false
      t.references :subject, null: false, foreign_key: true

      t.timestamps
    end
  end
end
