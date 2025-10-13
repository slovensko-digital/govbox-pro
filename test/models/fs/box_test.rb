# frozen_string_literal: true

require "test_helper"

class Fs::BoxTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#after_create callback sets syncable value to true if tenant fs_sync feature is enabled" do
    tenant = tenants(:accountants)
    tenant.enable_feature(:fs_sync)

    box = tenant.boxes.create(
      name: 'Test box',
      short_name: 'FS TB',
      uri: 'dic://sk/0246802',
      type: 'Fs::Box',
      api_connections: [api_connections(:fs_api_connection1)]
    )

    assert box.reload.syncable
  end

  test "#after_create callback sets syncable value to false if tenant fs_sync feature is disabled" do
    tenant = tenants(:solver)

    box = tenant.boxes.create(
      name: 'Test box',
      short_name: 'FS TB',
      uri: 'dic://sk/0246802',
      type: 'Fs::Box',
      api_connections: [api_connections(:fs_api_connection2)]
    )

    assert_not box.reload.syncable
  end

  test "validates uniqueness of name scoped to tenant_id and uri" do
    tenant = tenants(:accountants)
    api_connection = api_connections(:fs_api_connection1)

    # Create original box
    Fs::Box.create!(
      name: "Unique Box Name",
      short_name: "UBN",
      uri: "dic://sk/123456789",
      tenant: tenant,
      api_connections: [api_connection]
    )

    # Should fail with same name, tenant_id, and uri
    duplicate_box = Fs::Box.new(
      name: "Unique Box Name",
      short_name: "Different",
      uri: "dic://sk/123456789",
      tenant: tenant,
      api_connections: [api_connection]
    )
    assert_not duplicate_box.valid?
    assert_includes duplicate_box.errors[:name], "Názov ste už použili"

    # Should succeed with same name, same tenant, but different uri
    different_uri_box = Fs::Box.new(
      name: "Unique Box Name",
      short_name: "Different",
      uri: "dic://sk/987654321",
      tenant: tenant,
      api_connections: [api_connection]
    )
    assert different_uri_box.valid?

    # Should succeed with same name, same uri, but different tenant
    different_tenant_box = Fs::Box.new(
      name: "Unique Box Name",
      short_name: "Different",
      uri: "dic://sk/123456789",
      tenant: tenants(:solver),
      api_connections: [api_connections(:fs_api_connection2)]
    )
    assert different_tenant_box.valid?
  end

  test "validates uniqueness of short_name scoped to tenant_id" do
    tenant = tenants(:accountants)
    api_connection = api_connections(:fs_api_connection1)

    # Create original box
    Fs::Box.create!(
      name: "Original Box",
      short_name: "OB",
      uri: "dic://sk/123456789",
      tenant: tenant,
      api_connections: [api_connection]
    )

    # Should fail with same short_name, tenant_id, and uri
    duplicate_box = Fs::Box.new(
      name: "Different Name",
      short_name: "OB",
      uri: "dic://sk/123456789",
      tenant: tenant,
      api_connections: [api_connection]
    )
    assert_not duplicate_box.valid?
    assert_includes duplicate_box.errors[:short_name], "Krátky názov ste už použili"

    # Should fail with same short_name, same tenant even if different uri
    different_uri_box = Fs::Box.new(
      name: "Different Name",
      short_name: "OB",
      uri: "dic://sk/987654321",
      tenant: tenant,
      api_connections: [api_connection]
    )
    assert_not different_uri_box.valid?
    assert_includes different_uri_box.errors[:short_name], "Krátky názov ste už použili"

    # Should succeed with same short_name, same uri, but different tenant
    different_tenant_box = Fs::Box.new(
      name: "Different Name",
      short_name: "OB",
      uri: "dic://sk/123456789",
      tenant: tenants(:solver),
      api_connections: [api_connections(:fs_api_connection2)]
    )
    assert different_tenant_box.valid?
  end

  test "sync method schedules Fs::SyncBoxJob with highest priority" do
    box = boxes(:fs_accountants)

    assert_enqueued_with(job: Fs::SyncBoxJob, priority: -1000) do
      box.sync
    end
  end

  test "sync_all schedules sync of all boxes with selected API connections" do
    assert_enqueued_with(job: Fs::SyncBoxJob) do
      Fs::Box.sync_all
    end

    assert_enqueued_jobs Fs::Box.joins(:boxes_api_connections).group("boxes_api_connections.settings->>'delegate_id'").count.values.sum
  end
end
