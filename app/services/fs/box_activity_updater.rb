class Fs::BoxActivityUpdater
  def self.mark_connections_inactive(api_connection)
    api_connection.boxes_api_connections.find_each do |connection|
      settings = (connection.settings || {}).dup
      settings["active"] = false
      connection.update!(settings: settings)
    end
  end

  def self.refresh_box_activity(api_connection)
    box_ids = api_connection.boxes_api_connections.select(:box_id)

    Fs::Box.where(id: box_ids).includes(:boxes_api_connections).find_each do |box|
      box.refresh_active_from_connections
    end
  end
end
