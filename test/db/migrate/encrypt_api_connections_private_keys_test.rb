require "test_helper"
require Rails.root.glob("db/migrate/*_encrypt_api_connections_private_keys.rb").first

class EncryptApiConnectionsPrivateKeysTest < ActiveSupport::TestCase
  test "encrypts plaintext private keys so they are readable without unencrypted data support" do
    api_connection = api_connections(:fs_api_connection1)
    api_connection.encrypt
    private_key = OpenSSL::PKey::RSA.generate(2048).to_pem
    ApiConnection.where(id: api_connection.id).update_all(["api_token_private_key = ?", private_key])

    without_unencrypted_data_support do
      migrate_up

      api_connection = ApiConnection.find(api_connection.id)
      assert_not_includes raw_private_key(api_connection), "BEGIN"
      assert_equal private_key, api_connection.api_token_private_key
      assert_equal "1234567", api_connection.settings_username
    end
  end

  test "keeps already encrypted private keys readable" do
    api_connection = api_connections(:govbox_api_api_connection1)
    private_key = OpenSSL::PKey::RSA.generate(2048).to_pem
    api_connection.update!(api_token_private_key: private_key)

    without_unencrypted_data_support do
      migrate_up

      assert_equal private_key, ApiConnection.find(api_connection.id).api_token_private_key
    end
  end

  private

  def migrate_up
    ActiveRecord::Migration.suppress_messages { EncryptApiConnectionsPrivateKeys.new.migrate(:up) }
  end

  def raw_private_key(api_connection)
    ApiConnection.where(id: api_connection.id).pick(Arel.sql("api_token_private_key"))
  end

  def without_unencrypted_data_support
    previous = ActiveRecord::Encryption.config.support_unencrypted_data
    ActiveRecord::Encryption.config.support_unencrypted_data = false
    yield
  ensure
    ActiveRecord::Encryption.config.support_unencrypted_data = previous
  end
end
