require "test_helper"
require "zip"

class ExportJobTest < ActiveJob::TestCase
  test "PDF only export contains nested PDFs and PDF attachments but no original or unsupported files" do
    export = pdf_export
    export.update_settings('originals' => '0', 'message_direction' => 'outbox', 'templates' => { 'default' => '{{ subor.nazov }}' })
    object = message_objects(:fs_accountants_outbox_form)
    nested_pdf(object, name: 'first.pdf', content: '%PDF-first')
    nested_pdf(object, name: 'second.pdf', content: '%PDF-second')
    attachment(object.message, name: 'attachment.pdf', mimetype: Utils::PDF_MIMETYPE, content: '%PDF-attachment')
    attachment(object.message, name: 'notes.txt', mimetype: 'text/plain', content: 'Not a PDF')

    entries = export_entries(export)

    assert_equal({ 'SVDPHv20.pdf' => '%PDF-first', 'SVDPHv20 (1).pdf' => '%PDF-second', 'attachment.pdf' => '%PDF-attachment' }, entries)
    assert_equal export, Notifications::ExportFinished.last.export
  end

  test "existing export settings still include originals and PDF attachments are not duplicated" do
    export = pdf_export
    export.update_settings('message_direction' => 'outbox', 'templates' => { 'default' => '{{ subor.nazov }}' })
    object = message_objects(:fs_accountants_outbox_form)
    original_content = asice_with_pdf(object, content: '%PDF-form')
    attachment(object.message, name: 'attachment.pdf', mimetype: Utils::PDF_MIMETYPE, content: '%PDF-attachment')

    assert_equal({ 'SVDPHv20.asice' => original_content, 'SVDPHv20.pdf' => '%PDF-form', 'attachment.pdf' => '%PDF-attachment' }, export_entries(export))
  end

  test "original only export does not include PDF visualizations" do
    export = pdf_export
    export.update_settings('pdf' => '0', 'message_direction' => 'outbox', 'templates' => { 'default' => '{{ subor.nazov }}' })
    object = message_objects(:fs_accountants_outbox_form)
    original_content = asice_with_pdf(object, content: '%PDF-form')

    assert_equal({ 'SVDPHv20.asice' => original_content }, export_entries(export))
  end

  test "PDF only export writes generated visualizations" do
    export = pdf_export
    export.update_settings('originals' => '0', 'templates' => { 'default' => '{{ subor.nazov }}' })
    object = message_objects(:fs_accountants_outbox_xml_form)
    job = ExportJob.new
    buffer = object.stub(:downloadable_as_pdf?, true) do
      object.stub(:prepare_pdf_visualization, '%PDF-generated') do
        ::Zip::OutputStream.write_buffer do |zip|
          job.prepare_pdf_object(object, export: export, zip: zip, file_paths: [])
        end
      end
    end

    ::Zip::File.open_buffer(buffer) do |zip|
      assert_equal ['SVDPHv20.pdf'], zip.entries.map(&:name)
      assert_equal '%PDF-generated', zip.read('SVDPHv20.pdf')
    end
  end

  test "thread title with slash is replaced with dash in ZIP entry path" do
    thread = message_threads(:fs_accountants_thread1)
    thread.update!(title: "DPH/2025/Q1")

    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "default" => "1", "templates" => { "default" => "{{ vlakno.nazov }}/{{ subor.nazov }}" } }
    )

    object = message_objects(:fs_accountants_outbox_form)
    file_paths = []
    path = export.export_object_filepath(object, other_file_names: file_paths)

    parts = path.split("/")
    assert_equal "DPH-2025-Q1", parts.first, "Slash in thread title should produce dash, not extra directory level"
    assert_equal 2, parts.length, "Path should have exactly 2 segments (sanitized title / filename)"
  end

  test "filtered_messages with date range only yields messages within range" do
    thread = message_threads(:fs_accountants_thread1)
    outbox_message = messages(:fs_accountants_thread1_outbox_message)
    past_date = (outbox_message.delivered_at.to_date - 1.year).iso8601

    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true, "delivered_at_to" => past_date }
    )

    messages = export.message_threads.flat_map { |t| export.filtered_messages(t).to_a }
    assert_not_includes messages, outbox_message, "Messages after 'to' date should be excluded"
  end

  test "filtered_messages with from date after all messages returns empty set" do
    thread = message_threads(:fs_accountants_thread1)
    future_date = (Date.today + 1.year).iso8601

    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "messages" => true, "default" => true, "delivered_at_from" => future_date }
    )

    messages = export.message_threads.flat_map { |t| export.filtered_messages(t).to_a }
    assert_empty messages, "No messages should match a from date in the future"
  end

  test "vlakno.nazov appears in ZIP file path when used in template" do
    thread = message_threads(:fs_accountants_thread1)
    export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [thread.id],
      settings: { "default" => "1", "templates" => { "default" => "{{ vlakno.nazov }}/{{ subor.nazov }}" } }
    )

    object = message_objects(:fs_accountants_outbox_form)
    file_paths = []
    path = export.export_object_filepath(object, other_file_names: file_paths)
    assert path.start_with?("#{thread.title}/"), "Expected path to start with thread title, got: #{path}"
  end

  test "an object whose PDF visualization is unavailable fails the export rather than shipping it incomplete" do
    export = pdf_export
    object = message_objects(:fs_accountants_outbox_form)
    file_paths = []

    error = object.stub(:nested_message_objects, []) do
      object.stub(:downloadable_as_pdf?, true) do
        object.stub(:prepare_pdf_visualization, nil) do
          assert_raises(ExportJob::PdfVisualizationFailed) do
            ::Zip::OutputStream.write_buffer do |zip|
              ExportJob.new.prepare_pdf_object(object, export: export, zip: zip, file_paths: file_paths)
            end
          end
        end
      end
    end

    assert_match(/Unable to prepare PDF visualization/, error.message)
    assert_empty file_paths, "Nothing should be recorded for a PDF we never got"
  end

  test "a nested object whose PDF visualization is unavailable fails the export too" do
    export = pdf_export
    object = message_objects(:fs_accountants_outbox_form)
    file_paths = []

    nested = object.nested_message_objects.create!(name: "form.xml", mimetype: "application/x-eform-xml",
                                                   content: "<x/>")

    error = nested.stub(:downloadable_as_pdf?, true) do
      nested.stub(:prepare_pdf_visualization, nil) do
        object.stub(:nested_message_objects, [ nested ]) do
          assert_raises(ExportJob::PdfVisualizationFailed) do
            ::Zip::OutputStream.write_buffer do |zip|
              ExportJob.new.prepare_pdf_object(object, export: export, zip: zip, file_paths: file_paths)
            end
          end
        end
      end
    end

    assert_match(/Unable to prepare PDF visualization/, error.message)
    assert_empty file_paths
  end

  test "a failing export gives up instead of retrying forever like ApplicationJob does" do
    assert_equal Float::INFINITY, retry_attempts(ApplicationJob, "StandardError"),
                 "Guard: this test only means something while ApplicationJob retries forever"
    assert_equal 3, retry_attempts(ExportJob, "ExportJob::PdfVisualizationFailed")
  end

  test "an export that exhausts its retries tells the user instead of going silent" do
    export = pdf_export

    assert_difference -> { Notifications::ExportFailed.count }, 1 do
      ExportJob.new(export).send(:run_after_discard_procs, StandardError.new("boom"))
    end

    assert_equal export, Notifications::ExportFailed.last.export
  end

  test "a queued export keeps waiting for a slot instead of spending its failure budget" do
    assert_equal "GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError",
                 handler_for(ExportJob, GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError),
                 "Broadening our retry to StandardError would shadow GoodJob's concurrency back-off"
  end

  test "a nested object the export template skips does not abandon the nested objects after it" do
    export = pdf_export
    object = message_objects(:fs_accountants_outbox_form)
    nested_pdf(object, name: "first.pdf", content: "%PDF-1")
    nested_pdf(object, name: "second.pdf", content: "%PDF-2")
    file_paths = []
    job = ExportJob.new

    paths = [ nil, "second.pdf" ]
    export.stub(:export_object_filepath, ->(*, **) { paths.shift }) do
      ::Zip::OutputStream.write_buffer do |zip|
        job.prepare_pdf_object(object, export: export, zip: zip, file_paths: file_paths)
      end
    end

    assert_equal ["second.pdf"], file_paths, "Skipping one nested object must not drop the rest"
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
      settings: { "pdf" => "1", "by_type" => { "ED.DeliveryReport" => "1" }, "default" => "1", "templates" => { "default" => "{{ schranka.oficialny_nazov }}/{{ vlakno.obdobie }}_{{ subor.nazov }}", "ED.DeliveryReport" => "{{ schranka.oficialny_nazov }}/{{ schranka.oficialny_nazov }}_{{ vlakno.obdobie }}_potvrdenie" } }
    )

    outbox_message = messages(:fs_accountants_thread1_outbox_message)
    inbox_message = messages(:fs_accountants_thread1_inbox_message)

    file_paths = []

    file_paths << export.export_object_filepath(outbox_message.form_object, other_file_names: file_paths, pdf: false)
    assert_equal "Accountants main FS/Q22025_SVDPHv20.asice", file_paths.last
    file_paths << export.export_object_filepath(outbox_message.form_object, other_file_names: file_paths, pdf: true)
    assert_equal "Accountants main FS/Q22025_SVDPHv20.pdf", file_paths.last

    file_paths << export.export_object_filepath(inbox_message.form_object, other_file_names: file_paths, pdf: false)
    assert_equal "Accountants main FS/Accountants main FS_Q22025_potvrdenie.asice", file_paths.last
    file_paths << export.export_object_filepath(inbox_message.form_object, other_file_names: file_paths, pdf: true)
    assert_equal "Accountants main FS/Accountants main FS_Q22025_potvrdenie.pdf", file_paths.last
  end

  test "generates export file names according to settings and handles duplicate names" do
    export = Export.create(
      user: users(:accountants_basic),
      message_thread_ids: [
        message_threads(:fs_accountants_thread1).id
      ],
      settings: { "pdf" => "1", "by_type" => { "ED.DeliveryReport" => "1" }, "default" => "1", "templates" => { "default" => "{{ schranka.oficialny_nazov }}/{{ vlakno.obdobie }}", "ED.DeliveryReport" => "{{ schranka.oficialny_nazov }}/{{ vlakno.obdobie }}" } }
    )

    outbox_message = messages(:fs_accountants_thread1_outbox_message)
    inbox_message = messages(:fs_accountants_thread1_inbox_message)

    file_paths = []

    file_paths << export.export_object_filepath(outbox_message.form_object, other_file_names: file_paths, pdf: false)
    assert_equal "Accountants main FS/Q22025.asice", file_paths.last
    file_paths << export.export_object_filepath(outbox_message.form_object, other_file_names: file_paths, pdf: true)
    assert_equal "Accountants main FS/Q22025.pdf", file_paths.last

    file_paths << export.export_object_filepath(inbox_message.form_object, other_file_names: file_paths, pdf: false)
    assert_equal "Accountants main FS/Q22025 (1).asice", file_paths.last
    file_paths << export.export_object_filepath(inbox_message.form_object, other_file_names: file_paths, pdf: true)
    assert_equal "Accountants main FS/Q22025 (1).pdf", file_paths.last
  end

  test "generates export file names according to settings and handles special characters" do
    export = Export.create(
      user: users(:accountants_basic),
      message_thread_ids: [
        message_threads(:fs_accountants_thread1).id
      ],
      settings: { "pdf" => "1", "by_type" => { "ED.DeliveryReport" => "1" }, "default" => "1", "templates" => { "default" => "{{ schranka.oficialny_nazov }}/{{ subor.nazov }}", "ED.DeliveryReport" => "{{ schranka.oficialny_nazov }}/{{ subor.nazov }}" } }
    )

    message = messages(:ssd_main_draft_to_be_signed3_draft_two)

    file_paths = []

    file_paths << export.export_object_filepath(message.objects.first, other_file_names: file_paths, pdf: false)
    assert_equal "SSD main/1234-Rozh_o_pokute_§155_ods.1_písm.g)_no.asice", file_paths.last
    file_paths << export.export_object_filepath(message.objects.first, other_file_names: file_paths, pdf: true)
    assert_equal "SSD main/1234-Rozh_o_pokute_§155_ods.1_písm.g)_no.pdf", file_paths.last

    file_paths << export.export_object_filepath(message.objects.second, other_file_names: file_paths, pdf: false)
    assert_equal "SSD main/MyString", file_paths.last
    file_paths << export.export_object_filepath(message.objects.second, other_file_names: file_paths, pdf: true)
    assert_equal "SSD main/MyString.pdf", file_paths.last

    file_paths << export.export_object_filepath(message.objects.last, other_file_names: file_paths, pdf: false)
    assert_equal "SSD main/1234-Rozh_o_pokute_§155_ods.1_písm.g)_no (1).asice", file_paths.last
    file_paths << export.export_object_filepath(message.objects.last, other_file_names: file_paths, pdf: true)
    assert_equal "SSD main/1234-Rozh_o_pokute_§155_ods.1_písm.g)_no (1).pdf", file_paths.last
  end

  def retry_attempts(job, error_name)
    job.rescue_handlers.reverse.find { |klass, _| klass == error_name }
       .last.binding.local_variable_get(:attempts)
  end

  def handler_for(job, error)
    job.rescue_handlers.reverse.find { |klass, _| error <= Object.const_get(klass) }.first
  end

  # nested_message_objects has no fixtures, so these are real rows on a fixture's parent.
  def nested_pdf(object, name:, content:)
    object.nested_message_objects.create!(name: name, mimetype: Utils::PDF_MIMETYPE, content: content)
  end

  def pdf_export
    Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [message_threads(:fs_accountants_thread1).id],
      settings: { "messages" => true, "pdf" => "1", "default" => "1" }
    )
  end

  def attachment(message, name:, mimetype:, content:)
    object = message.objects.create!(name: name, mimetype: mimetype, object_type: 'ATTACHMENT')
    object.create_message_object_datum!(blob: content)
    object
  end

  def asice_with_pdf(object, content:)
    bytes = ::Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry('form.pdf')
      zip.write(content)
    end.string.b
    object.create_message_object_datum!(blob: bytes)
    bytes
  end

  def export_entries(export)
    entries = nil
    storage = Minitest::Mock.new
    storage.expect(:store, nil) do |directory, filename, content|
      assert_equal 'exports', directory
      assert_equal export.file_name, filename
      ::Zip::File.open_buffer(StringIO.new(content.b)) do |zip|
        entries = zip.entries.to_h { |entry| [entry.name, entry.get_input_stream.read] }
      end
      true
    end
    FileStorage.stub(:new, storage) { ExportJob.new.perform(export) }
    storage.verify
    entries
  end
end
