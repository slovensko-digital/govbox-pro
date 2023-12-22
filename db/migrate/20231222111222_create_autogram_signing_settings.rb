class CreateAutogramSigningSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :autogram_signing_settings do |t|

      t.timestamps
    end
  end
end
