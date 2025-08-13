require 'csv'

class ExportJob < ApplicationJob
  queue_as :default

  def perform(export)
    file_paths = []

    export_content = ::Zip::OutputStream.write_buffer do |zip|
      if export.settings.dig("messages")
        export.message_threads.each do |message_thread|
          message_thread.messages.each do |message|
            message.objects.each do |object|
              prepare_original_object(object, export: export, zip: zip, file_paths: file_paths)
              prepare_pdf_object(object, export: export, zip: zip, file_paths: file_paths) if export.settings["pdf"]

              EventBus.publish(:message_object_downloaded, object)
            end
          end
        end
      end

      if export.settings.dig("summary")
        prepare_summary(export: export, zip: zip)
      end
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
    summary_data = CSV.generate(headers: true) do |csv|
      csv << export.message_threads
                   .flat_map(&:messages)
                   .flat_map(&:export_summary)
                   .map(&:keys)
                   .flatten
                   .uniq

      export.message_threads.each do |message_thread|
        message_thread.messages.each do |message|
          csv << message.export_summary
        end
      end
    end

    zip.put_next_entry("sumár.csv")
    zip.write(summary_data.force_encoding('UTF-8'))
  end

  def unique_path_within_export(object, export:, other_file_names:, pdf: false)
    path = export.export_object_filepath(object)
    return unless path

    extension = pdf ? ".pdf" : File.extname(object.name)
    path_without_extension = path.delete_suffix(File.extname(object.name))
    path_with_extension = "#{path_without_extension}#{extension}"

    return path_with_extension unless path_with_extension.in?(other_file_names)

    matches_count = other_file_names.count { |name| /#{path_without_extension}( \(\d+\))?#{extension}/ =~ name }
    "#{path_without_extension} (#{matches_count})#{extension}"
  end
end
