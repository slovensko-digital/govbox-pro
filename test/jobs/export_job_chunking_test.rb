require "test_helper"
require "zip"

class ExportJobChunkingTest < ActiveJob::TestCase
  teardown do
    clear_enqueued_jobs
    return unless @export

    FileUtils.rm_f(@export.storage_path)
    FileUtils.rm_f("#{@export.storage_path}.tmp")
    FileUtils.rm_rf(parts_dir)
  end

  test "export larger than one batch chains jobs and finishes with a single zip + notification" do
    create_export("summary" => true)

    assert_enqueued_with(job: ExportJob) do
      ExportJob.perform_later(@export, batch_size: 1)
    end

    perform_enqueued_jobs while enqueued_jobs.any?

    assert File.exist?(@export.storage_path), "final single ZIP should exist"

    entries = zip_entry_names
    assert_includes entries, "sumar.xlsx"
    assert entries.size > 1, "ZIP should contain entries from both chunks, got: #{entries.inspect}"
    assert_equal 1, finished_count, "exactly one finished notification for the single ZIP"
    assert_not File.exist?(parts_dir), "part files should be cleaned up after merge"
  end

  test "first chunk enqueues follow-up instead of finishing" do
    create_export

    assert_enqueued_with(job: ExportJob) do
      ExportJob.new.perform(@export, offset: 0, file_paths: [], batch_size: 1)
    end

    assert_equal 0, finished_count
    assert File.exist?(File.join(parts_dir, "part-0.zip")), "first chunk part file should exist"
    assert_not File.exist?(@export.storage_path), "final ZIP must not exist before last chunk"
  end

  test "summary-only export writes no parts and finishes with just the summary" do
    create_export("messages" => false, "summary" => true)

    ExportJob.new.perform(@export, offset: 0, file_paths: [], batch_size: 1)

    assert File.exist?(@export.storage_path)
    assert_equal ["sumar.xlsx"], zip_entry_names
    assert_equal 1, finished_count
    assert_not File.exist?(parts_dir), "no parts should exist for a summary-only export"
  end

  test "export with no matching messages still produces a valid zip" do
    create_export("summary" => true, "delivered_at_from" => (Date.today + 1.year).iso8601)

    ExportJob.perform_later(@export, batch_size: 1)
    perform_enqueued_jobs while enqueued_jobs.any?

    assert File.exist?(@export.storage_path)
    assert_includes zip_entry_names, "sumar.xlsx"
    assert_equal 1, finished_count
  end

  test "re-running a chunk is idempotent and still yields a single complete zip" do
    create_export("summary" => true)

    ExportJob.new.perform(@export, offset: 0, file_paths: [], batch_size: 1)
    clear_enqueued_jobs

    retry_paths = []
    ExportJob.new.perform(@export, offset: 0, file_paths: retry_paths, batch_size: 1)
    clear_enqueued_jobs

    assert_equal 1, Dir[File.join(parts_dir, "part-*.zip")].size, "retry must not duplicate part files"
    ExportJob.new.perform(@export, offset: 1, file_paths: retry_paths, batch_size: 1)

    assert File.exist?(@export.storage_path)
    entries = zip_entry_names
    assert entries.size > 1, "ZIP should contain entries from both chunks, got: #{entries.inspect}"
    assert_equal 1, finished_count
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

  def zip_entry_names
    names = []
    ::Zip::File.open(@export.storage_path) { |zip| zip.each { |entry| names << entry.name unless entry.directory? } }
    names
  end

  def finished_count
    @export.user.notifications.where(export: @export, type: "Notifications::ExportFinished").count
  end
end
