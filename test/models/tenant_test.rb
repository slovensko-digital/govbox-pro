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
end
