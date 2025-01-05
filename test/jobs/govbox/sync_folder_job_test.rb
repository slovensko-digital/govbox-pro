require "test_helper"

class Govbox::SyncFolderJobTest < ActiveJob::TestCase
  test "downloads all messages unless box sync_since value in box settings set" do
    folder = govbox_folders(:ssd_one)

    edesk_api_mock = Minitest::Mock.new
    edesk_api_mock.expect :fetch_messages, [200, [
      {
        "id"=>4905707493,
        "class"=>"ED_DELIVERY_NOTIFICATION",
        "message_id"=>"7cb378ef-9c76-493b-b41d-51f1e40dd68e",
        "correlation_id"=>"6baa28c3-96e5-493b-a76c-9837a6d637b3",
        "subject"=>"Notifikácia o doručení k \"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia\"",
        "delivered_at"=>"2023-07-10T09:51:36.533Z"
      },
      {
        "id"=>4906445420,
        "class"=>"EGOV_DOCUMENT",
        "message_id"=>"1fe26465-ff59-4fed-b948-630cc994507a",
        "correlation_id"=>"5aeddd85-952e-4534-a9fd-9c73774049f3",
        "subject"=>"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia",
        "delivered_at"=>"2023-07-14T12:51:50.337Z"
      },
      {
        "id"=>4906376126,
        "class"=>"EGOV_DOCUMENT",
        "message_id"=>"1d5f449c-7b8e-40d6-9662-64ff0af527cd",
        "correlation_id"=>"7f2956fd-d8d8-4062-9d34-f9b0418c9f0b",
        "subject"=>"Všeobecná agenda - rozhodnutie do vlastných rúk",
        "delivered_at"=>"2023-07-15T14:16:32.600Z"
      },
      {
        "id"=>4905707496,
        "class"=>"ED_DELIVERY_NOTIFICATION",
        "message_id"=>"14fe42a3-c3b7-419b-bb76-485f49543e53",
        "correlation_id"=>"8c359d95-3d72-4e76-b0f2-ddeba11c3b5b",
        "subject"=>"Notifikácia o doručení k \"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia\"",
        "delivered_at"=>"2023-08-10T09:51:36.560Z"
      },
      {
        "id"=>4905707497,
        "class"=>"ED_DELIVERY_NOTIFICATION",
        "message_id"=>"14fe42a3-c3b7-419b-bb76-485f49543e53",
        "correlation_id"=>"8c359d95-3d72-4e76-b0f2-ddeba11c3b5b",
        "subject"=>"Notifikácia o doručení k \"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia\"",
        "delivered_at"=>"2023-08-11T09:51:36.560Z"
      },
    ]], [folder.edesk_folder_id], **{ page: 1, count: 5 }
    edesk_api_mock.expect :fetch_messages, [200, [
      {
        "id"=>4905707493,
        "class"=>"ED_DELIVERY_NOTIFICATION",
        "message_id"=>"7cb378ef-9c76-493b-b41d-51f1e40dd68e",
        "correlation_id"=>"6baa28c3-96e5-493b-a76c-9837a6d637b3",
        "subject"=>"Notifikácia o doručení k \"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia\"",
        "delivered_at"=>"2023-08-12T09:51:36.533Z"
      },
      {
        "id"=>4906445420,
        "class"=>"EGOV_DOCUMENT",
        "message_id"=>"1fe26465-ff59-4fed-b948-630cc994507a",
        "correlation_id"=>"5aeddd85-952e-4534-a9fd-9c73774049f3",
        "subject"=>"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia",
        "delivered_at"=>"2023-08-14T12:51:50.337Z"
      },
      {
        "id"=>4906376126,
        "class"=>"EGOV_DOCUMENT",
        "message_id"=>"1d5f449c-7b8e-40d6-9662-64ff0af527cd",
        "correlation_id"=>"7f2956fd-d8d8-4062-9d34-f9b0418c9f0b",
        "subject"=>"Všeobecná agenda - rozhodnutie do vlastných rúk",
        "delivered_at"=>"2023-11-15T14:16:32.600Z"
      },
      {
        "id"=>4905707496,
        "class"=>"ED_DELIVERY_NOTIFICATION",
        "message_id"=>"14fe42a3-c3b7-419b-bb76-485f49543e53",
        "correlation_id"=>"8c359d95-3d72-4e76-b0f2-ddeba11c3b5b",
        "subject"=>"Notifikácia o doručení k \"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia\"",
        "delivered_at"=>"2024-07-10T09:51:36.560Z"
      }
    ]], [folder.edesk_folder_id], **{ page: 2, count: 5 }

    ::Upvs::GovboxApi::Edesk.stub :new, edesk_api_mock do
      Govbox::SyncFolderJob.new.perform(folder, batch_size: 5)
    end

    assert_enqueued_jobs 9
  end

  test "does not download older messages than box sync_since value in box settings" do
    box = boxes(:ssd_main)
    box.settings['sync_since'] = '2023-11-15'
    box.save

    folder = govbox_folders(:ssd_one)

    edesk_api_mock = Minitest::Mock.new
    edesk_api_mock.expect :fetch_messages, [200, [
      {
        "id"=>4905707493,
        "class"=>"ED_DELIVERY_NOTIFICATION",
        "message_id"=>"7cb378ef-9c76-493b-b41d-51f1e40dd68e",
        "correlation_id"=>"6baa28c3-96e5-493b-a76c-9837a6d637b3",
        "subject"=>"Notifikácia o doručení k \"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia\"",
        "delivered_at"=>"2023-07-10T09:51:36.533Z"
      },
      {
        "id"=>4906445420,
        "class"=>"EGOV_DOCUMENT",
        "message_id"=>"1fe26465-ff59-4fed-b948-630cc994507a",
        "correlation_id"=>"5aeddd85-952e-4534-a9fd-9c73774049f3",
        "subject"=>"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia",
        "delivered_at"=>"2023-11-14T12:51:50.337Z"
      },
      {
        "id"=>4906376126,
        "class"=>"EGOV_DOCUMENT",
        "message_id"=>"1d5f449c-7b8e-40d6-9662-64ff0af527cd",
        "correlation_id"=>"7f2956fd-d8d8-4062-9d34-f9b0418c9f0b",
        "subject"=>"Všeobecná agenda - rozhodnutie do vlastných rúk",
        "delivered_at"=>"2023-11-15T14:16:32.600Z"
      },
      {
        "id"=>4905707496,
        "class"=>"ED_DELIVERY_NOTIFICATION",
        "message_id"=>"14fe42a3-c3b7-419b-bb76-485f49543e53",
        "correlation_id"=>"8c359d95-3d72-4e76-b0f2-ddeba11c3b5b",
        "subject"=>"Notifikácia o doručení k \"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia\"",
        "delivered_at"=>"2024-07-10T09:51:36.560Z"
      },
    ]], [folder.edesk_folder_id], **{ page: 1, count: 1000 }

    ::Upvs::GovboxApi::Edesk.stub :new, edesk_api_mock do
      Govbox::SyncFolderJob.new.perform(folder)
    end

    assert_enqueued_jobs 2
  end

  test "starts fetching messages from selected folder page and downloads only messages from selected ID (folder settings)" do
    box = boxes(:ssd_main)
    box.settings['sync_since'] = '2023-11-15'
    box.save

    folder = govbox_folders(:ssd_one)
    folder.settings['sync_from_page'] = 9
    folder.settings['sync_from_message_id'] = 4905707495
    folder.save

    edesk_api_mock = Minitest::Mock.new
    edesk_api_mock.expect :fetch_messages, [200, [
      {
        "id"=>4905707493,
        "class"=>"ED_DELIVERY_NOTIFICATION",
        "message_id"=>"7cb378ef-9c76-493b-b41d-51f1e40dd68e",
        "correlation_id"=>"6baa28c3-96e5-493b-a76c-9837a6d637b3",
        "subject"=>"Notifikácia o doručení k \"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia\"",
        "delivered_at"=>"2023-07-10T09:51:36.533Z"
      },
      {
        "id"=>4905707494,
        "class"=>"EGOV_DOCUMENT",
        "message_id"=>"1fe26465-ff59-4fed-b948-630cc994507a",
        "correlation_id"=>"5aeddd85-952e-4534-a9fd-9c73774049f3",
        "subject"=>"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia",
        "delivered_at"=>"2023-11-14T12:51:50.337Z"
      },
      {
        "id"=>4905707495,
        "class"=>"EGOV_DOCUMENT",
        "message_id"=>"1d5f449c-7b8e-40d6-9662-64ff0af527cd",
        "correlation_id"=>"7f2956fd-d8d8-4062-9d34-f9b0418c9f0b",
        "subject"=>"Všeobecná agenda - rozhodnutie do vlastných rúk",
        "delivered_at"=>"2023-11-15T14:16:32.600Z"
      },
      {
        "id"=>4905707496,
        "class"=>"ED_DELIVERY_NOTIFICATION",
        "message_id"=>"14fe42a3-c3b7-419b-bb76-485f49543e53",
        "correlation_id"=>"8c359d95-3d72-4e76-b0f2-ddeba11c3b5b",
        "subject"=>"Notifikácia o doručení k \"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia\"",
        "delivered_at"=>"2024-07-10T09:51:36.560Z"
      },
    ]], [folder.edesk_folder_id], **{ page: 10, count: 1000 }


    ::Upvs::GovboxApi::Edesk.stub :new, edesk_api_mock do
      Govbox::SyncFolderJob.new.perform(folder)
    end

    assert_enqueued_jobs 2
  end

  test "raises if downloading messages from selected ID and smaller ID is found (box settings)" do
    box = boxes(:ssd_main)
    box.settings['sync_since'] = '2023-11-15'
    box.save

    folder = govbox_folders(:ssd_one)
    folder.settings['sync_from_page'] = 9
    folder.settings['sync_from_message_id'] = 4906376126
    folder.save

    edesk_api_mock = Minitest::Mock.new
    edesk_api_mock.expect :fetch_messages, [200, [
      {
        "id"=>4905707493,
        "class"=>"ED_DELIVERY_NOTIFICATION",
        "message_id"=>"7cb378ef-9c76-493b-b41d-51f1e40dd68e",
        "correlation_id"=>"6baa28c3-96e5-493b-a76c-9837a6d637b3",
        "subject"=>"Notifikácia o doručení k \"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia\"",
        "delivered_at"=>"2023-07-10T09:51:36.533Z"
      },
      {
        "id"=>4906445420,
        "class"=>"EGOV_DOCUMENT",
        "message_id"=>"1fe26465-ff59-4fed-b948-630cc994507a",
        "correlation_id"=>"5aeddd85-952e-4534-a9fd-9c73774049f3",
        "subject"=>"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia",
        "delivered_at"=>"2023-11-14T12:51:50.337Z"
      },
      {
        "id"=>4906376126,
        "class"=>"EGOV_DOCUMENT",
        "message_id"=>"1d5f449c-7b8e-40d6-9662-64ff0af527cd",
        "correlation_id"=>"7f2956fd-d8d8-4062-9d34-f9b0418c9f0b",
        "subject"=>"Všeobecná agenda - rozhodnutie do vlastných rúk",
        "delivered_at"=>"2023-11-15T14:16:32.600Z"
      },
      {
        "id"=>4905707496,
        "class"=>"ED_DELIVERY_NOTIFICATION",
        "message_id"=>"14fe42a3-c3b7-419b-bb76-485f49543e53",
        "correlation_id"=>"8c359d95-3d72-4e76-b0f2-ddeba11c3b5b",
        "subject"=>"Notifikácia o doručení k \"Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia\"",
        "delivered_at"=>"2024-07-10T09:51:36.560Z"
      },
    ]], [folder.edesk_folder_id], **{ page: 10, count: 1000 }

    assert_raise('MessageID out of order!') do
      ::Upvs::GovboxApi::Edesk.stub :new, edesk_api_mock do
        Govbox::SyncFolderJob.new.perform(folder)
      end
    end
  end
end
