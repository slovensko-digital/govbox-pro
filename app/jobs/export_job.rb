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
              prepare_original_object(object, export: export, zip: zip, file_paths: file_paths) if export.settings_object.originals
              prepare_pdf_object(object, export: export, zip: zip, file_paths: file_paths)

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
    file_path = export.export_object_filepath(object, other_file_names: file_paths)
    return unless file_path

    zip.put_next_entry(file_path)
    zip.write(object.content)
    file_paths << file_path
  end

  def prepare_pdf_object(object, export:, zip:, file_paths:)
    return unless export.settings['pdf']
    return if export.settings_object.originals && object.pdf?

    objects = object.nested_message_objects.presence || [object]
    objects.each do |pdf_object|
      next unless pdf_object.pdf? || pdf_object.downloadable_as_pdf?

      pdf_content = pdf_object.pdf? ? pdf_object.content : pdf_visualization(pdf_object)

      file_path = export.export_object_filepath(object, other_file_names: file_paths, pdf: true)
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
end
