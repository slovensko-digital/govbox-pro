require "test_helper"
require "zip"

class ExportJobChunkingTest < ActiveJob::TestCase
  teardown do
    clear_enqueued_jobs
    (@pdf_stubs || []).each { |stub| stub[:active] = false }
    return unless @export

    FileUtils.rm_f(@export.storage_path)
    FileUtils.rm_f("#{@export.storage_path}.tmp")
    FileUtils.rm_rf(parts_dir)
  end

  test "export larger than one batch chains jobs and finishes with a single zip + notification" do
    create_export("summary" => true)

    with_download_events(record: ->(object) { [object.id, File.exist?(@export.storage_path)] }) do |published|
      run_export

      entries = zip_entry_names
      assert File.exist?(@export.storage_path), "final single ZIP should exist"
      assert_includes entries, "sumar.xlsx"
      assert entries.size > 1, "ZIP should contain entries from both chunks, got: #{entries.inspect}"
      assert_equal 1, finished_count, "exactly one finished notification for the single ZIP"
      assert_not File.exist?(parts_dir), "part files should be cleaned up after merge"
      assert_equal expected_object_ids.sort, published.map(&:first).sort, "each object exactly once"
      assert published.all?(&:last), "every event must fire after the final ZIP is saved"
    end
  end

  test "summary-only export writes no parts and finishes with just the summary" do
    create_export("messages" => false, "summary" => true)

    with_download_events do |published|
      ExportJob.new.perform(@export, offset: 0, batch_size: 1)

      assert File.exist?(@export.storage_path)
      assert_equal ["sumar.xlsx"], zip_entry_names
      assert_equal 1, finished_count
      assert_not File.exist?(parts_dir), "no parts should exist for a summary-only export"
      assert_empty published
    end
  end

  test "export with no matching messages still produces a valid zip" do
    create_export("summary" => true, "delivered_at_from" => (Date.current + 1.year).iso8601)

    run_export

    assert File.exist?(@export.storage_path)
    assert_includes zip_entry_names, "sumar.xlsx"
    assert_equal 1, finished_count
  end

  test "cross-batch filename collisions deduplicate across chunks and retries" do
    create_export("summary" => false, "pdf" => true, "templates" => { "default" => "{{ subor.nazov }}" })
    stub = stub_pdf_visualization(->(calls) { calls.size == 3 ? nil : "pdf-bytes" })

    with_download_events do |published|
      run_export

      assert_operator stub[:calls].size, :>=, 4, "guard: a retry must have happened"
      names = zip_entry_names
      assert_includes names, "DeliveryReport.asice"
      assert_includes names, "DeliveryReport (1).asice"
      assert names.none? { |n| n.include?("(2)") }, "retry must not treat failed batch names as taken, got: #{names.inspect}"
      assert_equal expected_object_ids.sort, published.sort
      assert_equal 1, finished_count
    end
  end

  test "a discarded export publishes no download events and cleans its parts" do
    create_export("summary" => true, "pdf" => true)
    stub = stub_pdf_visualization(->(calls) { calls.size >= 3 ? nil : "pdf-bytes" })

    with_download_events do |published|
      assert_raises(ExportJob::PdfVisualizationFailed) { run_export }

      assert_operator stub[:calls].size, :>=, 5, "guard: batch 0 should succeed and batch 1 should exhaust retries"
      assert_empty published, "failed export must not mark objects downloaded, got: #{published.inspect}"
      assert_equal 1, @export.user.notifications.where(export: @export, type: "Notifications::ExportFailed").count
      assert_not File.exist?(parts_dir), "discarded export should clean its parts"
      assert_empty @export.reload.parts, "discarded export should reset its part metadata"
    end
  end

  test "a notification failure after finalization does not overwrite the complete zip on retry" do
    create_export("summary" => true)
    ExportJob.new.perform(@export, offset: 0, batch_size: 1)
    clear_enqueued_jobs

    attempts = 0
    original = Notifications::ExportFinished.method(:create!)
    failing = ->(*args, **kwargs) do
      attempts += 1
      raise "notification failure" if attempts == 1

      original.call(*args, **kwargs)
    end

    with_download_events do |published|
      Notifications::ExportFinished.stub(:create!, failing) do
        assert_raises(RuntimeError) { ExportJob.new.perform(@export.reload, offset: 1, batch_size: 1) }

        assert File.exist?(@export.storage_path), "finalization should have produced the complete zip"
        assert @export.reload.finalized_at?, "finalized_at should be persisted before notification"
        completed_entries = zip_entry_names

        ExportJob.new.perform(@export.reload, offset: 1, batch_size: 1)

        assert_equal completed_entries, zip_entry_names
        assert_equal 1, finished_count
        assert_equal expected_object_ids.sort, published.sort, "events must be published exactly once"
        assert_not File.exist?(parts_dir)
      end
    end
  end

  test "a partial failure while publishing download events does not duplicate already published parts on retry" do
    create_export("summary" => true)
    ExportJob.new.perform(@export, offset: 0, batch_size: 1)
    clear_enqueued_jobs

    part0_object_ids = @export.reload.parts.dig("0", "object_ids")
    assert_not_empty part0_object_ids

    published = []
    failed_once = false
    sub = ->(object) do
      if !failed_once && !part0_object_ids.include?(object.id)
        failed_once = true
        raise "event bus failure"
      end
      published << object.id
    end
    EventBus.subscribe(:message_object_downloaded, sub)

    begin
      assert_raises(RuntimeError) { ExportJob.new.perform(@export.reload, offset: 1, batch_size: 1) }
      assert_equal part0_object_ids.sort, published.sort
      assert_equal 0, finished_count

      ExportJob.new.perform(@export.reload, offset: 1, batch_size: 1)

      assert_equal expected_object_ids.sort, published.sort, "part 0 objects must not be re-published on retry"
      assert_equal 1, finished_count
      assert_empty @export.reload.parts
      assert_not File.exist?(parts_dir)
    ensure
      EventBus.class_variable_get(:@@subscribers_map)[:message_object_downloaded].delete(sub)
    end
  end

  test "re-running a finalized export via start resets finalized_at and rebuilds with new settings" do
    create_export("summary" => true)
    run_export
    assert @export.reload.finalized_at?
    assert_includes zip_entry_names, "sumar.xlsx"

    @export.update_settings("summary" => false, "messages" => true)
    with_download_events do |published|
      @export.start
      perform_enqueued_jobs while enqueued_jobs.any?

      assert_not_includes zip_entry_names, "sumar.xlsx"
      assert_equal expected_object_ids.sort, published.sort
      assert_equal 2, finished_count
    end
  end

  test "re-running a finalized export does not rebuild it or duplicate events" do
    create_export("summary" => true)
    run_export

    @export.reload
    completed_inode = File.stat(@export.storage_path).ino

    with_download_events do |published|
      ExportJob.new.perform(@export, offset: 1, batch_size: 1)

      assert_equal completed_inode, File.stat(@export.storage_path).ino
      assert_empty published
      assert_equal 1, finished_count
    end
  end

  test "only objects actually written to a part get download events" do
    @export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: [message_threads(:fs_accountants_thread1).id],
      settings: {
        "messages" => true,
        "default" => false,
        "by_type" => { "ED.DeliveryReport" => true },
        "templates" => {
          "default" => "{{ subor.nazov }}",
          "ED.DeliveryReport" => "{{ subor.nazov }}"
        }
      }
    )

    expected = messages(:fs_accountants_thread1_inbox_message).objects.ids

    with_download_events do |published|
      run_export

      assert_equal expected.sort, published.sort
      assert_equal ["DeliveryReport.asice"], zip_entry_names
    end
  end

  test "an object added after its thread's part was built is neither zipped nor published" do
    create_export("summary" => true)
    ExportJob.new.perform(@export, offset: 0, batch_size: 1)
    clear_enqueued_jobs

    first_part_message = MessageObject.find(@export.reload.parts.dig("0", "object_ids").first).message
    expected_before_late_object = expected_object_ids.sort
    late_object = MessageObject.create!(
      message: first_part_message,
      name: "late.pdf",
      mimetype: "application/pdf",
      object_type: "ATTACHMENT",
      uuid: SecureRandom.uuid
    )
    MessageObjectDatum.create!(message_object: late_object, blob: "%PDF-1.4")

    with_download_events do |published|
      ExportJob.new.perform(@export.reload, offset: 1, batch_size: 1)

      assert_equal expected_before_late_object, published.sort
      assert_not_includes published, late_object.id
      assert_not_includes zip_entry_names, "late.pdf"
    end
  end

  test "chunked PDF-only export matches preview_filepaths with unsorted thread ids and reserved summary name" do
    threads = [message_threads(:fs_accountants_thread1), message_threads(:fs_accountants_thread2)].sort_by(&:id).reverse
    threads.each { |t| t.messages.inbox.first.form_object.nested_message_objects.create!(name: "form.pdf", mimetype: Utils::PDF_MIMETYPE, content: "%PDF-#{t.id}") }
    sheet = MessageObject.create!(message: threads.first.messages.first, name: "sumar.xlsx", mimetype: "application/octet-stream", object_type: "ATTACHMENT", uuid: SecureRandom.uuid)
    MessageObjectDatum.create!(message_object: sheet, blob: "bytes")
    @export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: threads.map(&:id),
      settings: { "messages" => true, "summary" => true, "originals" => true, "pdf" => true, "default" => true, "templates" => { "default" => "{{ subor.nazov }}" } }
    )

    preview = ExportJob.new.preview_filepaths(@export, message_threads: @export.message_threads).values.flatten
    run_export

    assert_includes zip_entry_names, "sumar (1).xlsx"
    assert_equal (preview + ["sumar.xlsx"]).sort, zip_entry_names.sort

    @export.update_settings("originals" => false, "summary" => false, "message_direction" => "inbox")
    @export.start
    perform_enqueued_jobs while enqueued_jobs.any?

    assert_equal ["DeliveryReport (1).pdf", "DeliveryReport.pdf"], zip_entry_names.sort
  end

  private

  def create_export(settings = {})
    threads = [message_threads(:fs_accountants_thread1), message_threads(:fs_accountants_thread2)]
    @export = Export.create!(
      user: users(:accountants_basic),
      message_thread_ids: threads.map(&:id),
      settings: { "messages" => true, "default" => true }.merge(settings)
    )
  end

  def parts_dir
    Rails.root.join("storage", "exports", "tmp", "export-#{@export.id}").to_s
  end

  def run_export(batch_size: 1)
    ExportJob.perform_later(@export, batch_size: batch_size)
    perform_enqueued_jobs while enqueued_jobs.any?
  end

  def with_download_events(record: ->(object) { object.id })
    published = []
    sub = ->(object) { published << record.call(object) }
    EventBus.subscribe(:message_object_downloaded, sub)
    begin
      yield published
    ensure
      EventBus.class_variable_get(:@@subscribers_map)[:message_object_downloaded].delete(sub)
    end
  end

  def expected_object_ids
    @export.message_threads.flat_map do |thread|
      @export.filtered_messages(thread).flat_map { |message| message.objects.ids }
    end
  end

  def stub_pdf_visualization(result_for)
    state = { active: true, calls: [] }
    override = Module.new do
      define_method(:downloadable_as_pdf?) { state[:active] ? true : super() }
      define_method(:prepare_pdf_visualization) do
        if state[:active]
          state[:calls] << id
          result_for.call(state[:calls])
        else
          super()
        end
      end
    end
    MessageObject.prepend(override)
    NestedMessageObject.prepend(override)
    (@pdf_stubs ||= []) << state
    state
  end

  def zip_entry_names
    names = []
    ::Zip::File.open(@export.storage_path) { |zip| zip.each { |entry| names << entry.name unless entry.directory? } }
    names
  end

  def finished_count
    @export.user.notifications.where(export: @export, type: "Notifications::ExportFinished").count
  end
end
