require "test_helper"

class TenantTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(name: "new one")
  end

  test "all system tags and groups are created with tenant" do
    assert @tenant.all_group
    assert @tenant.signer_group
    assert @tenant.admin_group
    assert @tenant.draft_tag
    assert @tenant.everything_tag
    assert @tenant.archived_tag
    assert @tenant.signature_requested_tag
    assert @tenant.signed_tag
    assert @tenant.signed_externally_tag
    assert_equal @tenant.everything_tag.groups, [@tenant.admin_group]
  end

  test "list_available_features parses ENV and filters invalid flags" do
    with_env_features("api, audit_log,  fake_feature ") do
      available = @tenant.list_available_features

      assert_includes available, :api
      assert_includes available, :audit_log
      assert_not_includes available, :fake_feature
      assert_equal 2, available.size
    end
  end

  test "enable_feature adds feature to flags if allowed" do
    with_env_features("api") do
      assert_not @tenant.feature_enabled?(:api)

      @tenant.enable_feature(:api)

      assert @tenant.feature_enabled?(:api)
      assert_includes @tenant.feature_flags, "api"
    end
  end

  test "enable_feature raises error if feature is not allowed" do
    with_env_features("audit_log") do
      error = assert_raises(RuntimeError) do
        @tenant.enable_feature(:api)
      end

      assert_match "Unknown feature api", error.message
    end
  end

  test "enable_feature raises error if feature is already enabled" do
    with_env_features("api") do
      @tenant.enable_feature(:api)

      assert_raises(RuntimeError) do
        @tenant.enable_feature(:api)
      end
    end
  end

  test "disable_feature removes feature from flags" do
    with_env_features("api") do
      @tenant.enable_feature(:api)
      assert @tenant.feature_enabled?(:api)

      @tenant.disable_feature(:api)

      assert_not @tenant.feature_enabled?(:api)
      assert_not_includes @tenant.feature_flags, "api"
    end
  end

  test "api_token_public_key is valid when nil" do
    @tenant.api_token_public_key = nil
    assert @tenant.valid?
  end

  test "api_token_public_key is invalid when an empty string" do
    @tenant.api_token_public_key = ""
    assert_not @tenant.valid?
    assert_includes @tenant.errors[:api_token_public_key], I18n.t('activerecord.errors.models.tenant.attributes.api_token_public_key.public_key_invalid_format')
  end

  test "api_token_public_key is valid with a correct 2048-bit RSA public key" do
    key = OpenSSL::PKey::RSA.generate(2048)
    @tenant.api_token_public_key = key.public_key.to_pem
    assert @tenant.valid?
  end

  test "api_token_public_key is invalid with a private key" do
    key = OpenSSL::PKey::RSA.generate(2048)
    @tenant.api_token_public_key = key.to_pem

    assert_not @tenant.valid?
    assert_includes @tenant.errors[:api_token_public_key], I18n.t('activerecord.errors.models.tenant.attributes.api_token_public_key.public_key_is_private')
  end

  test "api_token_public_key is invalid with a key of incorrect bit size" do
    key = OpenSSL::PKey::RSA.generate(1024)
    @tenant.api_token_public_key = key.public_key.to_pem

    assert_not @tenant.valid?
    expected_error = I18n.t('activerecord.errors.models.tenant.attributes.api_token_public_key.public_key_invalid_bits', current_bits: 1024)
    assert_includes @tenant.errors[:api_token_public_key], expected_error
  end

  test "api_token_public_key is invalid with a malformed string" do
    @tenant.api_token_public_key = "invalid-api-token-public-key"

    assert_not @tenant.valid?
    assert_includes @tenant.errors[:api_token_public_key], I18n.t('activerecord.errors.models.tenant.attributes.api_token_public_key.public_key_invalid_format')
  end
end
