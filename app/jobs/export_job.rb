class ExportJob < ApplicationJob
  queue_as :default

  def perform(export)
    file_paths = []

    export_content = ::Zip::OutputStream.write_buffer do |zip|
      export.message_threads.each do |message_thread|
        message_thread.messages.each do |message|
          message.objects.each do |object|
            prepare_original_object(object, export: export, zip: zip, file_paths: file_paths)
            prepare_pdf_object(object, export: export, zip: zip, file_paths: file_paths) if export.settings["pdf"]
          end
        end
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

  def unique_path_within_export(object, export:, other_file_names:, pdf: false)
    file_path = export.export_object_filepath(object)
    return unless file_path

    file_path_without_extension = file_path_without_extension(file_path, object.name)
    file_path_with_extension = file_path_with_extension(file_path_without_extension, object.name, pdf: pdf)

    if file_path_with_extension.in?(other_file_names)
      file_extension = file_extension(object.name, pdf: pdf)

      matches_count = other_file_names.count { |name| /#{file_path_without_extension}( \(\d+\))?#{file_extension}/ =~ name }

      file_path_with_extension = File.join(file_path_without_extension  + " (#{matches_count})" + file_extension) if matches_count > 0
    end

    file_path_with_extension
  end

  def file_path_with_extension(file_path, file_name, pdf: false)
    if pdf
      file_path + '.pdf'
    else
      file_path + File.extname(file_name)
    end
  end

  def file_path_without_extension(file_path, file_name)
    file_path.delete_suffix(File.extname(file_name))
  end

  def file_extension(file_name, pdf: false)
    if pdf
      '.pdf'
    else
      File.extname(file_name)
    end
  end
end
