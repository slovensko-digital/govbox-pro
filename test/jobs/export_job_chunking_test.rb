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
      ExportJob.new.perform(@export, offset: 0, file_paths: [], batch_size: 1)

      assert File.exist?(@export.storage_path)
      assert_equal ["sumar.xlsx"], zip_entry_names
      assert_equal 1, finished_count
      assert_not File.exist?(parts_dir), "no parts should exist for a summary-only export"
      assert_empty published
    end
  end

  test "export with no matching messages still produces a valid zip" do
    create_export("summary" => true, "delivered_at_from" => (Date.today + 1.year).iso8601)

    run_export

    assert File.exist?(@export.storage_path)
    assert_includes zip_entry_names, "sumar.xlsx"
    assert_equal 1, finished_count
  end

  test "a batch that fails once then succeeds ships clean names and single events" do
    create_export("summary" => true, "pdf" => true)
    stub = stub_pdf_visualization(->(calls) { calls.size == 3 ? nil : "pdf-bytes" })

    with_download_events do |published|
      run_export

      assert_operator stub[:calls].size, :>=, 2, "guard: a retry must have happened"
      names = zip_entry_names
      assert names.none? { |n| n.include?("(1)") }, "retry must rebuild names from scratch, got: #{names.inspect}"
      assert_equal expected_object_ids.sort, published.sort, "each object exactly once"
      assert_equal 1, finished_count
    end
  end

  test "a discarded export publishes no download events" do
    create_export("summary" => true, "pdf" => true)
    stub = stub_pdf_visualization(->(calls) { calls.size.even? ? nil : "pdf-bytes" })

    with_download_events do |published|
      assert_raises(ExportJob::PdfVisualizationFailed) { run_export }

      assert_operator stub[:calls].size, :>=, 3, "guard: retries must have been attempted"
      assert_empty published, "failed export must not mark objects downloaded, got: #{published.inspect}"
      assert_equal 1, @export.user.notifications.where(export: @export, type: "Notifications::ExportFailed").count
    end
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
