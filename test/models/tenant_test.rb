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

  test "agp configuration falls back to env and tenant settings override it" do
    env_key = OpenSSL::PKey::RSA.generate(2048)
    tenant_key = OpenSSL::PKey::RSA.generate(2048)
    env_webhook_key = OpenSSL::PKey::EC.generate("prime256v1")
    tenant_webhook_key = OpenSSL::PKey::EC.generate("prime256v1")

    with_agp_env(
      url: "https://env.agp.example",
      sub: "env-subject",
      private_key: Base64.strict_encode64(env_key.to_pem),
      webhook_public_key: env_webhook_key.public_to_pem
    ) do
      assert_equal "https://env.agp.example", @tenant.agp_api_url
      assert_equal "env-subject", @tenant.agp_sub
      assert_equal env_key.to_pem, @tenant.agp_api_token_private_key
      assert_equal env_webhook_key.public_to_pem, @tenant.agp_webhook_public_key

      @tenant.update!(
        settings_agp_api_url: "https://tenant.agp.example",
        settings_agp_sub: "tenant-subject",
        settings_agp_api_token_private_key: tenant_key.to_pem,
        settings_agp_webhook_public_key: tenant_webhook_key.public_to_pem
      )

      assert_equal "https://tenant.agp.example", @tenant.agp_api_url
      assert_equal "tenant-subject", @tenant.agp_sub
      assert_equal tenant_key.to_pem, @tenant.agp_api_token_private_key
      assert_equal tenant_webhook_key.public_to_pem, @tenant.agp_webhook_public_key
    end
  end

  test "agp webhook env fallback normalizes escaped newlines" do
    env_key = OpenSSL::PKey::EC.generate("prime256v1")

    with_agp_env(
      url: "https://env.agp.example",
      sub: "env-subject",
      private_key: Base64.strict_encode64(OpenSSL::PKey::RSA.generate(2048).to_pem),
      webhook_public_key: env_key.public_to_pem.gsub("\n", "\\n")
    ) do
      assert_equal env_key.public_to_pem, @tenant.agp_webhook_public_key
      assert OpenSSL::PKey::EC.new(@tenant.agp_webhook_public_key)
    end
  end

  test "agp_signing_enabled requires tenant flag and resolved configuration" do
    env_key = OpenSSL::PKey::RSA.generate(2048)

    with_env_features("autogram_portal") do
      with_agp_env(
        url: "https://env.agp.example",
        sub: "env-subject",
        private_key: Base64.strict_encode64(env_key.to_pem)
      ) do
        assert_not @tenant.agp_signing_enabled?

        @tenant.enable_feature(:autogram_portal)

        assert @tenant.agp_signing_enabled?
      end
    end
  end

  test "stored agp private key must be a valid 2048-bit rsa private key" do
    @tenant.settings_agp_api_token_private_key = "invalid-private-key"

    assert_not @tenant.valid?
    assert_includes @tenant.errors[:settings_agp_api_token_private_key], I18n.t("activerecord.errors.models.tenant.attributes.settings_agp_api_token_private_key.private_key_invalid_format")
  end

  test "stored agp webhook public key must be a valid ec public key" do
    @tenant.settings_agp_webhook_public_key = "invalid-public-key"

    assert_not @tenant.valid?
    assert_includes @tenant.errors[:settings_agp_webhook_public_key], I18n.t("activerecord.errors.models.tenant.attributes.settings_agp_webhook_public_key.public_key_invalid_format")
  end

  private

  def with_agp_env(url:, sub:, private_key:, webhook_public_key: nil)
    original_url = ENV.fetch("AGP_API_URL", nil)
    original_sub = ENV.fetch("AGP_API_SUB", nil)
    original_private_key = ENV.fetch("AGP_API_TOKEN_PRIVATE_KEY", nil)
    original_webhook_public_key = ENV.fetch("AGP_WEBHOOK_PUBLIC_KEY", nil)

    ENV["AGP_API_URL"] = url
    ENV["AGP_API_SUB"] = sub
    ENV["AGP_API_TOKEN_PRIVATE_KEY"] = private_key
    ENV["AGP_WEBHOOK_PUBLIC_KEY"] = webhook_public_key

    yield
  ensure
    ENV["AGP_API_URL"] = original_url
    ENV["AGP_API_SUB"] = original_sub
    ENV["AGP_API_TOKEN_PRIVATE_KEY"] = original_private_key
    ENV["AGP_WEBHOOK_PUBLIC_KEY"] = original_webhook_public_key
  end
end
