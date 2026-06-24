require "test_helper"
require "zip"

class ExportJobTest < ActiveJob::TestCase
  test "vlakno.nazov appears in ZIP file path when used in template" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "default" => "1", "templates" => { "default" => "{{ vlakno.nazov }}/{{ subor.nazov }}" } }
    )

    object = message_objects(:fs_accountants_outbox_form)
    file_paths = []
    path = ExportJob.new.unique_path_within_export(object, export: export, other_file_names: file_paths)
    assert path.start_with?("#{thread.title}/"), "Expected path to start with thread title, got: #{path}"
  end

  test "thread_title column appears in summary XLSX headers" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "summary" => true, "messages" => true, "default" => true }
    )

    xlsx_bytes = nil
    ::Zip::OutputStream.write_buffer do |zip|
      ExportJob.new.prepare_summary(export: export, zip: zip)
      zip.put_next_entry("dummy")
      zip.write("x")
    end

    messages = export.message_threads.flat_map { |t| export.filtered_messages(t).to_a }
    headers = messages.flat_map(&:export_summary).map(&:keys).flatten.uniq
    assert_includes headers, :thread_title
  end

  test "prepare_summary with message_direction 'outbox' only includes outbox rows" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "summary" => true, "message_direction" => "outbox" }
    )

    messages = export.message_threads.flat_map { |t| export.filtered_messages(t).to_a }
    assert messages.all?(&:outbox), "Expected only outbox messages in filtered result"
    assert_equal thread.messages.outbox.count, messages.count
  end

  test "prepare_summary with message_direction 'inbox' only includes inbox rows" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "summary" => true, "message_direction" => "inbox" }
    )

    messages = export.message_threads.flat_map { |t| export.filtered_messages(t).to_a }
    assert messages.none?(&:outbox), "Expected only inbox messages in filtered result"
    assert_equal thread.messages.inbox.count, messages.count
  end

  test "prepare_summary with message_direction 'all' includes all messages" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "summary" => true, "message_direction" => "all" }
    )

    messages = export.message_threads.flat_map { |t| export.filtered_messages(t).to_a }
    assert_equal thread.messages.count, messages.count
  end

  test "generates export file names according to settings" do
    export = Export.create(
      user: users(:accountants_basic),
      message_thread_ids: [
        message_threads(:fs_accountants_thread1).id
      ],
      settings: {"pdf"=>"1", "by_type"=>{"ED.DeliveryReport"=>"1"}, "default"=>"1", "templates"=>{"default"=>"{{ schranka.oficialny_nazov }}/{{ vlakno.obdobie }}_{{ subor.nazov }}", "ED.DeliveryReport"=>"{{ schranka.oficialny_nazov }}/{{ schranka.oficialny_nazov }}_{{ vlakno.obdobie }}_potvrdenie"}}
    )

    outbox_message = messages(:fs_accountants_thread1_outbox_message)
    inbox_message = messages(:fs_accountants_thread1_inbox_message)

    file_paths = []

    file_paths << ExportJob.new.unique_path_within_export(outbox_message.form_object, export: export, other_file_names: file_paths, pdf: false)
    assert_equal "Accountants main FS/Q22025_SVDPHv20.asice", file_paths.last
    file_paths << ExportJob.new.unique_path_within_export(outbox_message.form_object, export: export, other_file_names: file_paths, pdf: true)
    assert_equal "Accountants main FS/Q22025_SVDPHv20.pdf", file_paths.last

    file_paths << ExportJob.new.unique_path_within_export(inbox_message.form_object, export: export, other_file_names: file_paths, pdf: false)
    assert_equal "Accountants main FS/Accountants main FS_Q22025_potvrdenie.asice", file_paths.last
    file_paths << ExportJob.new.unique_path_within_export(inbox_message.form_object, export: export, other_file_names: file_paths, pdf: true)
    assert_equal "Accountants main FS/Accountants main FS_Q22025_potvrdenie.pdf", file_paths.last
  end

  test "generates export file names according to settings and handles duplicate names" do
    export = Export.create(
      user: users(:accountants_basic),
      message_thread_ids: [
        message_threads(:fs_accountants_thread1).id
      ],
      settings: {"pdf"=>"1", "by_type"=>{"ED.DeliveryReport"=>"1"}, "default"=>"1", "templates"=>{"default"=>"{{ schranka.oficialny_nazov }}/{{ vlakno.obdobie }}", "ED.DeliveryReport"=>"{{ schranka.oficialny_nazov }}/{{ vlakno.obdobie }}"}}
    )

    outbox_message = messages(:fs_accountants_thread1_outbox_message)
    inbox_message = messages(:fs_accountants_thread1_inbox_message)

    file_paths = []

    file_paths << ExportJob.new.unique_path_within_export(outbox_message.form_object, export: export, other_file_names: file_paths, pdf: false)
    assert_equal "Accountants main FS/Q22025.asice", file_paths.last
    file_paths << ExportJob.new.unique_path_within_export(outbox_message.form_object, export: export, other_file_names: file_paths, pdf: true)
    assert_equal "Accountants main FS/Q22025.pdf", file_paths.last

    file_paths << ExportJob.new.unique_path_within_export(inbox_message.form_object, export: export, other_file_names: file_paths, pdf: false)
    assert_equal "Accountants main FS/Q22025 (1).asice", file_paths.last
    file_paths << ExportJob.new.unique_path_within_export(inbox_message.form_object, export: export, other_file_names: file_paths, pdf: true)
    assert_equal "Accountants main FS/Q22025 (1).pdf", file_paths.last
  end

  test "generates export file names according to settings and handles special characters" do
    export = Export.create(
      user: users(:accountants_basic),
      message_thread_ids: [
        message_threads(:fs_accountants_thread1).id
      ],
      settings: {"pdf"=>"1", "by_type"=>{"ED.DeliveryReport"=>"1"}, "default"=>"1", "templates"=>{"default"=>"{{ schranka.oficialny_nazov }}/{{ subor.nazov }}", "ED.DeliveryReport"=>"{{ schranka.oficialny_nazov }}/{{ subor.nazov }}"}}
    )

    message = messages(:ssd_main_draft_to_be_signed3_draft_two)

    file_paths = []

    file_paths << ExportJob.new.unique_path_within_export(message.objects.first, export: export, other_file_names: file_paths, pdf: false)
    assert_equal "SSD main/1234-Rozh_o_pokute_§155_ods.1_písm.g)_no.asice", file_paths.last
    file_paths << ExportJob.new.unique_path_within_export(message.objects.first, export: export, other_file_names: file_paths, pdf: true)
    assert_equal "SSD main/1234-Rozh_o_pokute_§155_ods.1_písm.g)_no.pdf", file_paths.last

    file_paths << ExportJob.new.unique_path_within_export(message.objects.second, export: export, other_file_names: file_paths, pdf: false)
    assert_equal "SSD main/MyString", file_paths.last
    file_paths << ExportJob.new.unique_path_within_export(message.objects.second, export: export, other_file_names: file_paths, pdf: true)
    assert_equal "SSD main/MyString.pdf", file_paths.last

    file_paths << ExportJob.new.unique_path_within_export(message.objects.last, export: export, other_file_names: file_paths, pdf: false)
    assert_equal "SSD main/1234-Rozh_o_pokute_§155_ods.1_písm.g)_no (1).asice", file_paths.last
    file_paths << ExportJob.new.unique_path_within_export(message.objects.last, export: export, other_file_names: file_paths, pdf: true)
    assert_equal "SSD main/1234-Rozh_o_pokute_§155_ods.1_písm.g)_no (1).pdf", file_paths.last
  end
end
