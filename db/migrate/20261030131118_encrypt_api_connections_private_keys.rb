# frozen_string_literal: true

class EncryptApiConnectionsPrivateKeys < ActiveRecord::Migration[8.1]
  def up
    ApiConnection.find_each do |api_connection|
      next if api_connection.encrypted_attribute?(:api_token_private_key)

      # read the raw value, decrypting plaintext fails without support_unencrypted_data
      plaintext = api_connection.read_attribute_before_type_cast(:api_token_private_key)
      api_connection.update_columns(api_token_private_key: plaintext)
    end
  end
end
