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

  test "sync_all schedules sync of all boxes" do
    assert_enqueued_with(job: Govbox::SyncBoxJob) do
      Box.sync_all
    end

    assert_enqueued_jobs Upvs::Box.where(syncable: true).count
  end

  test "should not be valid if same obo value present in other boxes within connection" do
    box = boxes(:google_box_with_govbox_api_connection_with_obo_support)

    new_box = Box.create(
      name: SecureRandom.hex,
      short_name: SecureRandom.hex,
      uri: SecureRandom.hex,
      tenant: box.tenant,
      api_connection: box.api_connection,
      settings_obo: box.settings_obo
    )

    assert_not new_box.valid?
    assert_equal :settings_obo, new_box.errors.first.attribute
  end

  test "should not be valid if no obo value already present in other boxes within connection" do
    box = boxes(:google_box_with_govbox_api_connection_with_obo_support_without_obo_value)

    new_box = Box.create(
      name: SecureRandom.hex,
      short_name: SecureRandom.hex,
      uri: SecureRandom.hex,
      tenant: box.tenant,
      api_connection: box.api_connection,
      settings_obo: ''
    )

    assert_not new_box.valid?
    assert_equal :settings_obo, new_box.errors.first.attribute
  end

  test "after_destroy callback destroys api_connection if Govbox::ApiConnection without any boxes" do
    box = boxes(:google_box_with_govbox_api_connection)
    api_connection = box.api_connection

    box.destroy

    assert api_connection.destroyed?
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
end
