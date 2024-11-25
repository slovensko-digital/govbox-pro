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

class BoxTest < ActiveSupport::TestCase
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

  test "sync method schedules Govbox::SyncBoxJob with highest priority" do
    box = boxes(:ssd_main)

    box.sync
    assert_equal "Govbox::SyncBoxJob", GoodJob::Job.last.job_class
    assert_equal -1000, GoodJob::Job.last.priority
  end

  test "sync_all schedules sync of all boxes" do
    Box.sync_all
    assert_equal "Govbox::SyncBoxJob", GoodJob::Job.last.job_class

    assert_equal Upvs::Box.where(syncable: true).count, GoodJob::Job.count
  end

  test "should not be valid if same obo value present in other boxes within connection" do
    box = boxes(:google_box_with_govbox_api_connection_with_obo_support)

    new_box = Upvs::Box.create(
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

    new_box = Upvs::Box.create(
      name: SecureRandom.hex,
      short_name: SecureRandom.hex,
      uri: SecureRandom.hex,
      tenant: box.tenant,
      api_connection: box.api_connection
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
end
