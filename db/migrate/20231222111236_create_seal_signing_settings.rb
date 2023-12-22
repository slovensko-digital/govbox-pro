class CreateSealSigningSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :seal_signing_settings do |t|
      t.string :certificate_subject
      t.string :connection_sub

      t.timestamps
    end
  end
end
