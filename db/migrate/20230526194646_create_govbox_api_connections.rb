class CreateGovboxApiConnections < ActiveRecord::Migration[7.0]
  def change
    create_table :govbox_api_connections do |t|
      t.belongs_to :box, foreign_key: true

      t.string :sub, null: false
      t.uuid :obo
      t.string :api_token_private_key, null: false

      t.timestamps
    end
  end
end
