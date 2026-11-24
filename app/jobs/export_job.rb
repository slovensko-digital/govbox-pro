require 'axlsx'

class ExportJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_concurrency_rule(
    label: "ExportJob",
    apply_label: true,
    perform_limit: 2
  )

  class PdfVisualizationFailed < StandardError
  end

  retry_on PdfVisualizationFailed, wait: :polynomially_longer, attempts: 3

  after_discard do |job, _error|
    export = job.arguments.first
    cleanup_parts(export, reset_finalized: true)
    FileUtils.rm_f("#{export.storage_path}.tmp")
    export.user.notifications.create!(type: Notifications::ExportFailed, export: export)
  end

  queue_as :default

  THREADS_PER_BATCH = 25

  def perform(export, offset: 0, batch_size: THREADS_PER_BATCH)
    return finalize_export(export) if export.finalized_at?

    if export.settings.dig("messages")
      batch_ids = export.message_thread_ids[offset, batch_size] || []
      build_part(export, batch_ids, offset) if batch_ids.any?

      return ExportJob.set(job_context: :medium).perform_later(export, offset: offset + batch_size, batch_size: batch_size) if offset + batch_size < export.message_thread_ids.size
    end

    finalize_export(export)
  end

  def prepare_original_object(object, export:, zip:, file_paths:)
    file_path = unique_path_within_export(object, export: export, other_file_names: file_paths)
    return unless file_path

    zip.put_next_entry(file_path)
    zip.write(object.content)
    file_paths << file_path
  end

  def prepare_pdf_object(object, export:, zip:, file_paths:)
    if object.nested_message_objects.any?
      prepare_nested_print_objects(object, export: export, zip: zip, file_paths: file_paths)
    else
      return unless object.downloadable_as_pdf?

      pdf_content = pdf_visualization(object)

      file_path = unique_path_within_export(object, export: export, other_file_names: file_paths, pdf: true)
      return unless file_path

      zip.put_next_entry(file_path)
      zip.write(pdf_content)
      file_paths << file_path
    end
  end

  def prepare_nested_print_objects(object, export:, zip:, file_paths:)
    object.nested_message_objects.each do |nested_message_object|
      next unless nested_message_object.pdf? || nested_message_object.downloadable_as_pdf?

      pdf_content = if nested_message_object.pdf?
                      nested_message_object.content
                    else
                      pdf_visualization(nested_message_object)
                    end

      file_path = unique_path_within_export(object, export: export, other_file_names: file_paths, pdf: true)
      next unless file_path

      zip.put_next_entry(file_path)
      zip.write(pdf_content)
      file_paths << file_path
    end
  end

  def pdf_visualization(object)
    object.prepare_pdf_visualization || raise(PdfVisualizationFailed, pdf_visualization_failure(object))
  end

  def pdf_visualization_failure(object)
    "Unable to prepare PDF visualization for #{object.class.name} ID #{object.id}"
  end

  def prepare_summary(export:, zip:)
    messages = export.message_threads.flat_map { |t| export.filtered_messages(t).to_a }

    headers = messages
              .flat_map(&:export_summary)
              .map(&:keys)
              .flatten
              .uniq

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: "Sumár") do |sheet|
        sheet.add_row(headers)

        messages.each do |message|
          row_hash = message.export_summary
          row = headers.map do |h|
            v = row_hash[h]
            v.nil? ? nil : v.to_s
          end
          sheet.add_row(row)
        end
      end

      zip.put_next_entry('sumar.xlsx')
      zip.write(p.to_stream.read)
    end
  end

  def unique_path_within_export(object, export:, other_file_names:, pdf: false)
    path = export.export_object_filepath(object)
    return unless path

    object_name = MessageObjectHelper.displayable_name(object)

    extension = pdf ? ".pdf" : File.extname(object_name)
    path_without_extension = path.delete_suffix(File.extname(object_name))
    path_with_extension = "#{path_without_extension}#{extension}"

    return path_with_extension unless path_with_extension.in?(other_file_names)

    matches_count = other_file_names.count { |name| /#{Regexp.escape(path_without_extension)}( \(\d+\))?#{Regexp.escape(extension)}/ =~ name }
    "#{path_without_extension} (#{matches_count})#{extension}"
  end

  private

  def parts_dir(export)
    Rails.root.join("storage", "exports", "tmp", "export-#{export.id}").to_s
  end

  def part_path(export, offset)
    File.join(parts_dir(export), "part-#{offset}.zip")
  end

  def cleanup_parts(export, reset_finalized: false)
    FileUtils.rm_rf(parts_dir(export))
    updates = {}
    updates[:parts] = {} if export.parts.any?
    updates[:finalized_at] = nil if reset_finalized && export.finalized_at?
    export.update_columns(updates.merge(updated_at: Time.current)) if updates.any?
  end

  def build_part(export, batch_ids, offset)
    part_path = part_path(export, offset)
    tmp_path = "#{part_path}.tmp"
    FileUtils.mkdir_p(File.dirname(part_path))

    file_paths = export.parts
                       .select { |part_offset, _| part_offset.to_i < offset }
                       .flat_map { |_, part| part["file_paths"] || [] }
    seed_count = file_paths.size
    object_ids = []

    ::Zip::OutputStream.open(tmp_path) do |zip|
      batch_ids.each do |thread_id|
        message_thread = export.message_threads.find_by(id: thread_id)
        next unless message_thread

        export.filtered_messages(message_thread).includes(:thread, :objects).find_each do |message|
          message.objects.each do |object|
            file_paths_count = file_paths.size
            prepare_original_object(object, export: export, zip: zip, file_paths: file_paths)
            prepare_pdf_object(object, export: export, zip: zip, file_paths: file_paths) if export.settings["pdf"]

            object_ids << object.id if file_paths.size > file_paths_count
          end
        end
      end
    end

    FileUtils.mv(tmp_path, part_path)

    export.update_columns(
      parts: export.parts.merge(
        offset.to_s => {
          "object_ids" => object_ids.uniq,
          "file_paths" => file_paths.drop(seed_count)
        }
      ),
      updated_at: Time.current
    )
  end

  def finalize_export(export)
    unless export.finalized_at?
      final_tmp_path = "#{export.storage_path}.tmp"
      FileUtils.mkdir_p(File.dirname(export.storage_path))

      ::Zip::OutputStream.open(final_tmp_path) do |zip|
        export.parts.keys.map(&:to_i).sort.each do |offset|
          ::Zip::File.open(part_path(export, offset)) do |part_zip|
            part_zip.each do |entry|
              zip.put_next_entry(entry.name)
              zip.write(entry.get_input_stream.read)
            end
          end
        end

        prepare_summary(export: export, zip: zip) if export.settings.dig("summary")
      end

      FileUtils.mv(final_tmp_path, export.storage_path)
      export.update_columns(finalized_at: Time.current, updated_at: Time.current)
    end

    publish_download_events(export) if export.settings.dig("messages")
    cleanup_parts(export)

    started_id = export.user.notifications.where(export: export, type: "Notifications::ExportStarted").maximum(:id) || 0
    unless export.user.notifications.exists?(export: export, type: "Notifications::ExportFinished", id: (started_id + 1)..)
      Notifications::ExportFinished.create!(user: export.user, export: export)
    end
  end

  def publish_download_events(export)
    remaining = export.parts.dup

    remaining.keys.map(&:to_i).sort.each do |offset|
      key = offset.to_s
      object_ids = remaining.dig(key, "object_ids") || []

      MessageObject.where(id: object_ids).find_each do |object|
        EventBus.publish(:message_object_downloaded, object)
      end

      remaining.delete(key)
      export.update_columns(parts: remaining, updated_at: Time.current)
    end
  end
end
