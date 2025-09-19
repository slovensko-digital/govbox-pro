require "test_helper"

class BoxTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "should not be valid if obo value present in settings when api_connection is a Govbox::ApiConnection without tenant" do
    box = boxes(:google_box_with_govbox_api_connection)
    assert box.valid?

    box.settings_obo = SecureRandom.uuid

    assert_not box.valid?
  end

  test "should not be valid if obo value present in Govbox::ApiConnectionWithOboSupport" do
    box = boxes(:google_box_with_govbox_api_connection_with_obo_support)
    assert box.valid?

    box.api_connection.update(obo: SecureRandom.uuid)

    assert_not box.valid?
  end

  test "should not be valid if obo value present in SkApi::ApiConnectionWithOboSupport" do
    box = boxes(:google_box_with_sk_api_api_connection_with_obo_support)
    assert box.valid?

    box.api_connection.update(obo: SecureRandom.uuid)

    assert_not box.valid?
  end

  test "should not be valid if same obo value present in other boxes within connection" do
    box = boxes(:google_box_with_govbox_api_connection_with_obo_support)

    new_box = Upvs::Box.create(
      name: SecureRandom.hex,
      short_name: SecureRandom.hex,
      uri: SecureRandom.hex,
      tenant: box.tenant,
      api_connections: [box.api_connection],
      settings_obo: box.settings_obo
    )

    assert_not new_box.valid?
    assert_equal :settings_obo, new_box.errors.first.attribute
  end

  test "should not be valid if no obo value already present in other boxes within connection" do
    box = boxes(:google_box_with_govbox_api_connection_with_obo_support_without_obo_value)

    new_box = Upvs::Box.create(
      name: SecureRandom.hex,
      short_name: SecureRandom.hex,
      uri: SecureRandom.hex,
      tenant: box.tenant,
      api_connections: [box.api_connection]
    )

    assert_not new_box.valid?
    assert_equal :settings_obo, new_box.errors.first.attribute
  end

  test "should not be valid if api connection from different tenant set" do
    box = boxes(:google_box_with_govbox_api_connection_with_obo_support_without_obo_value)

    new_box = Upvs::Box.create(
      name: SecureRandom.hex,
      short_name: SecureRandom.hex,
      uri: SecureRandom.hex,
      tenant: box.tenant,
      api_connections: [api_connections(:govbox_api_api_connection_with_obo_support2)]
    )

    assert_not new_box.valid?
  end

  test "after_destroy callback destroys api_connection if Govbox::ApiConnection without any boxes" do
    box = boxes(:google_box_with_govbox_api_connection)
    api_connection = box.api_connection

    box.destroy

    assert_raises(ActiveRecord::RecordNotFound) { api_connection.reload }
  end

  test "before_save callback normalizes settings_obo attribute" do
    box = boxes(:google_box_with_govbox_api_connection).dup
    box.settings_obo = ''

    box.save

    assert_nil box.settings_obo
  end

  test "after_destroy callback does not destroy api_connection if Govbox::ApiConnectionWithOboSupport" do
    box = boxes(:google_box_with_govbox_api_connection_with_obo_support)
    api_connection = box.api_connection

    box.destroy

    assert_not api_connection.destroyed?
  end

  test "after_destroy callback does not destroy api_connection if SkApi::ApiConnectionWithOboSupport" do
    box = boxes(:google_box_with_sk_api_api_connection_with_obo_support)
    api_connection = box.api_connection

    box.destroy

    assert_not api_connection.destroyed?
  end

  test "export_name auto populated from official_name" do
    tenant = tenants(:solver)
    box = tenant.boxes.create!(
      name: 'FS Example Corp',
      short_name: 'FSEC',
      uri: 'dic://sk/1234500000',
      type: 'Fs::Box',
      api_connection: api_connections(:fs_api_connection2)
    )

    assert_equal 'Example Corp', box.export_name
  end
  
  test "sync method schedules Govbox::SyncBoxJob with highest priority" do
    box = boxes(:ssd_main)

    assert_enqueued_with(job: Govbox::SyncBoxJob, priority: -1000) do
      box.sync
    end
  end

  test "sync_all schedules sync of all boxes" do
    assert_enqueued_with(job: Govbox::SyncBoxJob) do
      Box.sync_all
    end

    assert_enqueued_jobs Box.where(syncable: true).count
  end
end
