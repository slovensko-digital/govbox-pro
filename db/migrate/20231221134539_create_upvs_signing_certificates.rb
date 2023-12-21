class CreateUpvsSigningCertificates < ActiveRecord::Migration[7.1]
  def change
    create_table :upvs_signing_certificates do |t|
      t.string :subject, null: false
      t.references :box, null: false, foreign_key: true

      t.timestamps
    end
  end
end
