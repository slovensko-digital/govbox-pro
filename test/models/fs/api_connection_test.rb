require "test_helper"

class Fs::ApiConnectionTest < ActiveSupport::TestCase
  test ".generate_short_name_from_name generates short name without number if unique" do
    api_connection = api_connections(:fs_api_connection1)
    assert_equal 'FSJH', api_connection.send(:generate_short_name_from_name, 'Janko Hraško')
  end

  test ".generate_short_name_from_name generates short name with number if not unique" do
    api_connection = api_connections(:fs_api_connection1)
    box = boxes(:fs_accountants)

    [
      'Juraj Jánošík',
      'Ján Jánošík',
      'Ján Jabĺčko',
      'Juraj Jabĺčko'
    ].each_with_index do |new_box_name, i|
      new_box = box.dup
      new_box.name = new_box_name
      new_box.uri = SecureRandom.hex
      new_box.short_name = api_connection.send(:generate_short_name_from_name, new_box_name)
      new_box.save

      assert_equal "FSJJ#{i + 1}", new_box.short_name
    end
  end
end
