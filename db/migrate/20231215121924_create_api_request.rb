class CreateApiRequest < ActiveRecord::Migration[7.1]
  def change
    create_table :api_requests do |t|
      t.string :endpoint_path, null: false
      t.string :endpoint_method, null: false
      t.integer :response_status, null: false
      t.string :authenticity_token, null: false
      t.inet :ip_address
      t.timestamps

      t.index [:ip_address, :created_at]
      t.index :created_at
      t.index [:endpoint_path, :created_at]
    end
  end
end
