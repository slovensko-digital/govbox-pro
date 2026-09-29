require 'axlsx'

class ExportJob < ApplicationJob
  queue_as :default

  THREADS_PER_BATCH = 25

  def perform(export, offset: 0, file_paths: [], batch_size: THREADS_PER_BATCH)
    if export.settings["messages"]
      batch_ids = export.message_thread_ids[offset, batch_size] || []
      build_part(export, batch_ids, File.join(parts_dir(export), "part-#{offset}.zip"), file_paths) if batch_ids.any?

      return ExportJob.set(job_context: :medium).perform_later(export, offset: offset + batch_size, file_paths: file_paths, batch_size: batch_size) if offset + batch_size < export.message_thread_ids.size
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

      pdf_content = object.prepare_pdf_visualization

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

      if nested_message_object.pdf?
        pdf_content = nested_message_object.content
      else
        pdf_content = nested_message_object.prepare_pdf_visualization
      end

      file_path = unique_path_within_export(object, export: export, other_file_names: file_paths, pdf: true)
      return nil unless file_path

      zip.put_next_entry(file_path)
      zip.write(pdf_content)
      file_paths << file_path
    end
  end

  def prepare_summary(export:, zip:)
    messages = export.message_threads.flat_map { |t| export.filtered_messages(t).to_a }

    headers = messages
              .flat_map(&:export_summary)
              .map(&:keys)
              .flatten
              .uniq

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "Sumár") do |sheet|
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

  def ordered_part_paths(export)
    Dir[File.join(parts_dir(export), "part-*.zip")].sort_by { |path| File.basename(path)[/\d+/].to_i }
  end

  def build_part(export, batch_ids, part_path, file_paths)
    tmp_path = "#{part_path}.tmp"
    FileUtils.mkdir_p(File.dirname(part_path))

    ::Zip::OutputStream.open(tmp_path) do |zip|
      batch_ids.each do |thread_id|
        message_thread = export.message_threads.find_by(id: thread_id)
        next unless message_thread

        export.filtered_messages(message_thread).includes(:thread, :objects).find_each do |message|
          message.objects.each do |object|
            prepare_original_object(object, export: export, zip: zip, file_paths: file_paths)
            prepare_pdf_object(object, export: export, zip: zip, file_paths: file_paths) if export.settings["pdf"]

            EventBus.publish(:message_object_downloaded, object)
          end
        end
      end
    end

    FileUtils.mv(tmp_path, part_path)
  end

  def finalize_export(export)
    final_tmp_path = "#{export.storage_path}.tmp"
    FileUtils.mkdir_p(File.dirname(export.storage_path))

    ::Zip::OutputStream.open(final_tmp_path) do |zip|
      ordered_part_paths(export).each do |part_path|
        ::Zip::File.open(part_path) do |part_zip|
          part_zip.each do |entry|
            zip.put_next_entry(entry.name)
            zip.write(entry.get_input_stream.read)
          end
        end
      end

      prepare_summary(export: export, zip: zip) if export.settings["summary"]
    end

    FileUtils.mv(final_tmp_path, export.storage_path)
    FileUtils.rm_rf(parts_dir(export))

    export.user.notifications.create!(
      type: Notifications::ExportFinished,
      export: export
    )
  end
end
