require "test_helper"

class Fs::ApiConnectionTest < ActiveSupport::TestCase
  test ".generate_short_name_from_name generates short name without number if unique" do
    api_connection = api_connections(:fs_api_connection1)
    assert_equal 'FSJH', api_connection.send(:generate_short_name_from_name, 'Janko Hraško')
  end

  test ".generate_short_name_from_name generates short name with number if not unique" do
    api_connection = api_connections(:fs_api_connection1)
    box = boxes(:fs_accountants)

    new_box = box.dup
    new_box.name = 'Juraj Jánošík'
    new_box.uri = SecureRandom.hex
    new_box.short_name = api_connection.send(:generate_short_name_from_name, 'Juraj Jánošík')
    new_box.save

    assert_equal "FSJJ1", new_box.short_name


    new_box = box.dup
    new_box.name = 'Ján Jánošík'
    new_box.uri = SecureRandom.hex
    new_box.short_name = api_connection.send(:generate_short_name_from_name, 'Ján Jánošík')
    new_box.save

    assert_equal "FSJJ2", new_box.short_name


    # skips number 3 which is already used
    new_box = box.dup
    new_box.name = 'Ján Jabĺčko'
    new_box.uri = SecureRandom.hex
    new_box.short_name = api_connection.send(:generate_short_name_from_name, 'Ján Jabĺčko')
    new_box.save

    assert_equal "FSJJ4", new_box.short_name


    new_box = box.dup
    new_box.name = 'Juraj Jabĺčko'
    new_box.uri = SecureRandom.hex
    new_box.short_name = api_connection.send(:generate_short_name_from_name, 'Juraj Jabĺčko')
    new_box.save

    assert_equal "FSJJ5", new_box.short_name
  end
end
