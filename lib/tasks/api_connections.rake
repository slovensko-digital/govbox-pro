namespace :api_connections do
  desc "Encrypt api_token_private_key on existing records (safe to re-run)"
  task encrypt_private_keys: :environment do
    encrypted = 0

    ApiConnection.find_each do |api_connection|
      next if api_connection.encrypted_attribute?(:api_token_private_key)

      api_connection.encrypt
      encrypted += 1
    end

    puts "Encrypted #{encrypted} of #{ApiConnection.count} api_connections."
  end
end
