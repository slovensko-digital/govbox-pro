# frozen_string_literal: true

require "test_helper"

class Fs::BoxTest < ActiveSupport::TestCase
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
end
