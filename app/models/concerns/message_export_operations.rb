# frozen_string_literal: true

module MessageExportOperations
  extend ActiveSupport::Concern

  included do
    def prepare_message_export
      file_names = []

      ::Zip::OutputStream.write_buffer do |zip|
        prepare_original_objects(zip, file_names)
        prepare_print_objects(zip, file_names)
      end.string
    end

    def pdf?
      Utils.mimetype_without_optional_params(mimetype) == Utils::PDF_MIMETYPE
    end

    private

    def prepare_original_objects(zip, file_names)
      objects.each do |message_object|
        file_name = MessageObjectHelper.unique_name_within_message(message_object, file_names)
        zip.put_next_entry("originaly/#{file_name}")
        zip.write(message_object.content)
        file_names << file_name
      end
    end

    def prepare_print_objects(zip, file_names)
      objects.each do |message_object|
        if message_object.nested_message_objects.any?
          prepare_nested_print_objects(zip, message_object, file_names)
        else
          next unless message_object.downloadable_as_pdf?

          pdf_content = message_object.prepare_pdf_visualization

          raise StandardError, "Unable to prepare PDF visualization for MessageObject ID #{message_object.id}" unless pdf_content

          file_name = MessageObjectHelper.unique_name_within_message(message_object, file_names, pdf: true)
          zip.put_next_entry(file_name)
          zip.write(pdf_content)
          file_names << file_name
        end
      end
    end

    def prepare_nested_print_objects(zip, message_object, file_names)
      message_object.nested_message_objects.each do |nested_message_object|
        next unless nested_message_object.pdf? || nested_message_object.downloadable_as_pdf?

        if nested_message_object.pdf?
          pdf_content = nested_message_object.content
        else
          pdf_content = nested_message_object.prepare_pdf_visualization
          raise StandardError, "Unable to prepare PDF visualization for MessageObject ID #{nested_message_object.id}" unless pdf_content
        end

        file_name = MessageObjectHelper.unique_name_within_message(nested_message_object, file_names, pdf: true)
        zip.put_next_entry(file_name)
        zip.write(pdf_content)
        file_names << file_name
      end
    end
  end
end
