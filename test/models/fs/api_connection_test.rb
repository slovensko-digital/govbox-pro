require "test_helper"

class Fs::ApiConnectionTest < ActiveSupport::TestCase
  test ".generate_short_name_from_name generates short name without number if unique" do
    api_connection = api_connections(:fs_api_connection1)
    assert_equal 'FSJH', api_connection.send(:generate_short_name_from_name, 'Janko Hraško')
  end

  test ".generate_short_name_from_name generates short name with number if not unique" do
    api_connection = api_connections(:fs_api_connection1)
    assert_equal 'FSJJ1', api_connection.send(:generate_short_name_from_name, 'Juraj Jánošík')
  end
end
