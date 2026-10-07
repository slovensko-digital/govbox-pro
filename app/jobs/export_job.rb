require 'axlsx'

class ExportJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(perform_limit: 2)

  class PdfVisualizationFailed < StandardError
  end

  retry_on PdfVisualizationFailed, wait: :polynomially_longer, attempts: 3

  after_discard do |job, _error|
    export = job.arguments.first
    export.user.notifications.create!(type: Notifications::ExportFailed, export: export)
  end

  queue_as :default

  def perform(export)
    file_paths = []

    export_content = ::Zip::OutputStream.write_buffer do |zip|
      if export.settings.dig("messages")
        export.message_threads.each do |message_thread|
          export.filtered_messages(message_thread).includes(:thread).each do |message|
            message.objects.each do |object|
              prepare_original_object(object, export: export, zip: zip, file_paths: file_paths)
              prepare_pdf_object(object, export: export, zip: zip, file_paths: file_paths) if export.settings["pdf"]

              EventBus.publish(:message_object_downloaded, object)
            end
          end
        end
      end

      prepare_summary(export: export, zip: zip) if export.settings.dig("summary")
    end

    FileStorage.new.store("exports", export.file_name, export_content.string.force_encoding("UTF-8"))

    export.user.notifications.create!(
      type: Notifications::ExportFinished,
      export: export
    )
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
end
