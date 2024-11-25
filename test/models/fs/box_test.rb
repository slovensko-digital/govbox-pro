# frozen_string_literal: true

# == Schema Information
#
# Table name: boxes
#
#  id                :bigint           not null, primary key
#  color             :enum
#  name              :string           not null
#  settings          :jsonb
#  short_name        :string
#  syncable          :boolean          default(TRUE), not null
#  type              :string
#  uri               :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  api_connection_id :bigint
#  tenant_id         :bigint           not null
#
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
      api_connection: api_connections(:fs_api_connection1)
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
      api_connection: api_connections(:fs_api_connection2)
    )

    assert_not box.reload.syncable
  end
end
