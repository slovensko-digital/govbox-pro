require "test_helper"

class Fs::BoxActivityUpdaterTest < ActiveSupport::TestCase
  test ".mark_connections_inactive sets settings_active to false" do
    api_connection = api_connections(:fs_api_connection1)
    api_connection.boxes_api_connections.update_all(settings: {})

    Fs::BoxActivityUpdater.mark_connections_inactive(api_connection)

    assert api_connection.boxes_api_connections.all? { |c| c.settings_active == false }
  end

  test ".refresh_box_activity sets box active when any connection active" do
    api_connection = api_connections(:fs_api_connection1)
    box = boxes(:fs_accountants)

    api_connection.boxes_api_connections.update_all(settings: {"active" => true})
    Fs::BoxActivityUpdater.refresh_box_activity(api_connection)
    assert box.reload.active

    api_connection.boxes_api_connections.update_all(settings: {"active" => false})
    Fs::BoxActivityUpdater.refresh_box_activity(api_connection)
    assert_not box.reload.active
  end
end
