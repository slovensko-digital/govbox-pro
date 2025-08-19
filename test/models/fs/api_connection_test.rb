require "test_helper"

class Fs::ApiConnectionTest < ActiveSupport::TestCase
  test ".boxify sets message_drafts_import_enabled attribute in settings" do
    original_fs_boxes_count = Fs::Box.count

    fs_api = Minitest::Mock.new
    fs_api.expect :get_subjects, [
      {"name" => "SSD s.r.o." , "dic" => "2120515056" , "subject_id" => SecureRandom.uuid, "authorization_type" => "6"},
      {"name" => "SSD s.r.o. (oblasť SPD)" , "dic" => "2120515056" , "subject_id" => SecureRandom.uuid, "authorization_type" => "6"},
      {"name" => "SSD s.r.o. (oblasť XYZ)" , "dic" => "2120515056" , "subject_id" => SecureRandom.uuid, "authorization_type" => "6"}
    ]

    api_connection = api_connections(:fs_api_connection1)

    FsEnvironment.fs_client.stub :api, fs_api do
      api_connection.boxify
    end

    assert_equal original_fs_boxes_count + 3, Fs::Box.count
    assert_equal true, Fs::Box.find_by(name: 'FS SSD s.r.o.').settings['message_drafts_import_enabled']
    assert_equal false, Fs::Box.find_by(name: 'FS SSD s.r.o. (oblasť SPD)').settings['message_drafts_import_enabled']
    assert_equal true, Fs::Box.find_by(name: 'FS SSD s.r.o. (oblasť XYZ)').settings['message_drafts_import_enabled']
  end

  test ".boxify ignores duplicated boxes with different authorization type" do
    original_fs_boxes_count = Fs::Box.count

    fs_api = Minitest::Mock.new
    fs_api.expect :get_subjects, [
      {"name" => "SSD s.r.o." , "dic" => "2120515056" , "subject_id" => "7e4faaa3-c130-4032-b4c1-d0892e9a4611", "authorization_type" => "6"},
      {"name" => "SSD s.r.o." , "dic" => "2120515056" , "subject_id" => "7e4faaa3-c130-4032-b4c1-d0892e9a4611", "authorization_type" => "1"},
      {"name" => "SSD s.r.o." , "dic" => "2120515056" , "subject_id" => "7e4faaa3-c130-4032-b4c1-d0892e9a4611", "authorization_type" => "4"}
    ]

    api_connection = api_connections(:fs_api_connection1)

    FsEnvironment.fs_client.stub :api, fs_api do
      api_connection.boxify
    end

    assert_equal original_fs_boxes_count + 1, Fs::Box.count
  end

  test ".boxify updates name on existing boxes if changed" do
    original_fs_boxes_count = Fs::Box.count
    existing_box = boxes(:fs_accountants2)

    fs_api = Minitest::Mock.new
    fs_api.expect :get_subjects, [
      {"name" => "Accountants main FS 2 new name" , "dic" => existing_box.settings_dic , "subject_id" => existing_box.settings_subject_id, "authorization_type" => "6"},
    ]

    api_connection = api_connections(:fs_api_connection1)

    FsEnvironment.fs_client.stub :api, fs_api do
      api_connection.boxify
    end

    assert_equal existing_box.reload.name, "FS Accountants main FS 2 new name"
    assert_equal original_fs_boxes_count, Fs::Box.count
  end

  test ".boxify adds c_reg on existing boxes if present" do
    original_fs_boxes_count = Fs::Box.count
    existing_box = boxes(:fs_accountants2)

    fs_api = Minitest::Mock.new
    fs_api.expect :get_subjects, [
      { "name" => existing_box.name, "dic" => existing_box.settings_dic, "subject_id" => existing_box.settings_subject_id, "authorization_type" => "6", "delegate_id" => "7e4faaa3-c130-4032-b4c1-d0892e9a4622", "is_subject_c_reg" => false }
    ]

    api_connection = api_connections(:fs_api_connection1)

    FsEnvironment.fs_client.stub :api, fs_api do
      api_connection.boxify
    end

    assert_equal existing_box.reload.settings_is_subject_c_reg, false
    assert_equal original_fs_boxes_count, Fs::Box.count
  end

  test ".boxify doesn't duplicate existing boxes if c_reg already present" do
    original_fs_boxes_count = Fs::Box.count
    existing_box = boxes(:fs_false_creg)

    fs_api = Minitest::Mock.new
    fs_api.expect :get_subjects, [
      { "name" => existing_box.name, "dic" => existing_box.settings_dic, "subject_id" => existing_box.settings_subject_id, "authorization_type" => "6", "is_subject_c_reg" => existing_box.settings_is_subject_c_reg, "delegate_id" => "7e4faaa3-c130-4032-b4c1-d0892e9a4622" }
    ]

    api_connection = api_connections(:fs_api_connection2)

    FsEnvironment.fs_client.stub :api, fs_api do
      api_connection.boxify
    end

    assert_equal original_fs_boxes_count, Fs::Box.count
    assert_equal existing_box.reload.settings_is_subject_c_reg, false
  end

  test ".generate_short_name_from_name generates short name without number if unique" do
    api_connection = api_connections(:fs_api_connection1)
    assert_equal 'FSJH', api_connection.send(:generate_short_name_from_name, 'Janko Hraško')
  end

  test ".generate_short_name_from_name generates short name with number if not unique" do
    api_connection = api_connections(:fs_api_connection1)
    box = boxes(:fs_accountants)

    new_box = box.dup
    new_box.api_connections = box.api_connections
    new_box.name = 'Juraj Jánošík'
    new_box.uri = SecureRandom.hex
    new_box.short_name = api_connection.send(:generate_short_name_from_name, 'Juraj Jánošík')
    new_box.save

    assert_equal "FSJJ1", new_box.short_name


    new_box = box.dup
    new_box.api_connections = box.api_connections
    new_box.name = 'Ján Jánošík'
    new_box.uri = SecureRandom.hex
    new_box.short_name = api_connection.send(:generate_short_name_from_name, 'Ján Jánošík')
    new_box.save

    assert_equal "FSJJ2", new_box.short_name


    # skips number 3 which is already used
    new_box = box.dup
    new_box.api_connections = box.api_connections
    new_box.name = 'Ján Jabĺčko'
    new_box.uri = SecureRandom.hex
    new_box.short_name = api_connection.send(:generate_short_name_from_name, 'Ján Jabĺčko')
    new_box.save

    assert_equal "FSJJ4", new_box.short_name


    new_box = box.dup
    new_box.api_connections = box.api_connections
    new_box.name = 'Juraj Jabĺčko'
    new_box.uri = SecureRandom.hex
    new_box.short_name = api_connection.send(:generate_short_name_from_name, 'Juraj Jabĺčko')
    new_box.save

    assert_equal "FSJJ5", new_box.short_name
  end

  test ".boxify sets other API connections" do
    original_fs_boxes_count = Fs::Box.count
    existing_box = boxes(:fs_accountants2)
    api_connection = existing_box.api_connection

    fs_api = Minitest::Mock.new
    fs_api.expect :get_subjects, [
      {"name" => existing_box.name , "dic" => existing_box.settings_dic , "subject_id" => existing_box.settings_subject_id, "authorization_type" => "6"},
    ]

    other_api_connection = api_connections(:fs_api_connection3)

    assert_equal 1, existing_box.api_connections.count

    FsEnvironment.fs_client.stub :api, fs_api do
      other_api_connection.boxify
    end

    assert_equal 2, existing_box.api_connections.count
    assert [api_connection.id, other_api_connection.id].sort == existing_box.api_connections.reload.map(&:id).sort
    assert_equal original_fs_boxes_count, Fs::Box.count
  end

  test ".boxify associates API connections to the existing box" do
    original_fs_boxes_count = Fs::Box.count

    api_connection = api_connections(:fs_api_connection3)

    fs_api = Minitest::Mock.new
    fs_api.expect :get_subjects, [
      {"subject_id"=>"ae968df6-6245-42c9-ad62-a590e20b20fe", "dic"=>"2020202020", "name"=>"Test subject, a.s.", "authorization_type" => "6", "delegate_id" => nil, "is_subject_c_reg" => false},
    ]

    FsEnvironment.fs_client.stub :api, fs_api do
      api_connection.boxify
    end

    box = Fs::Box.last

    assert_equal original_fs_boxes_count + 1, Fs::Box.count
    assert_equal "FS Test subject, a.s.", box.name
    assert_equal 1, box.api_connections.count
    assert_equal api_connection, box.api_connections.first
    assert_nil box.boxes_api_connections.find_by(api_connection: api_connection).settings_delegate_id

    api_connection = api_connections(:fs_api_connection4)

    fs_api = Minitest::Mock.new
    fs_api.expect :get_subjects, [
      {"subject_id"=>"ae968df6-6245-42c9-ad62-a590e20b20fe", "dic"=>"2020202020", "name"=>"Test subject, a.s.", "authorization_type" => "6", "delegate_id" => nil, "is_subject_c_reg" => false},
    ]

    FsEnvironment.fs_client.stub :api, fs_api do
      api_connection.boxify
    end

    assert_equal original_fs_boxes_count + 1, Fs::Box.count
    assert_equal 2, box.api_connections.count
    assert box.api_connections.include?(api_connection)
    assert_nil box.boxes_api_connections.find_by(api_connection: api_connection).settings_delegate_id

    api_connection = api_connections(:fs_api_connection5)

    fs_api = Minitest::Mock.new
    fs_api.expect :get_subjects, [
      {"subject_id"=>"ae968df6-6245-42c9-ad62-a590e20b20fe", "dic"=>"2020202020", "name"=>"Test subject, a.s. v zastúpení: SSD s. r. o.", "authorization_type" => "6", "delegate_id" => "4e34b214-108f-4cce-9219-ac8718eb9cdb", "is_subject_c_reg" => false},
    ]

    FsEnvironment.fs_client.stub :api, fs_api do
      api_connection.boxify
    end

    assert_equal original_fs_boxes_count + 1, Fs::Box.count
    assert_equal 3, box.api_connections.count
    assert box.api_connections.include?(api_connection)
    assert_equal "4e34b214-108f-4cce-9219-ac8718eb9cdb", box.boxes_api_connections.find_by(api_connection: api_connection).settings_delegate_id
  end
end
