class CreateSubmissionObjects < ActiveRecord::Migration[6.1]
  def change
    create_table 'submission.objects' do |t|
      t.references :submission, null: false, foreign_key: true

      t.uuid :uuid, null: false
      t.string :name, null: false
      t.boolean :signed
      t.boolean :to_be_signed
      t.binary :content, null: false
      t.boolean :form

      t.timestamps
    end
  end
end
