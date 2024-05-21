# frozen_string_literal: true

module MessageExportOperations
  extend ActiveSupport::Concern

  included do
    def prepare_message_export
      ::Zip::OutputStream.write_buffer do |zip|
        prepare_original_objects(zip)
        prepare_print_objects(zip)
      end.string
    end

    def pdf?
      Utils.mime_type_without_optional_params(mimetype) == Utils::PDF_MIMETYPE
    end

    private

    def prepare_original_objects(zip)
      objects.each do |message_object|
        zip.put_next_entry("originaly/#{MessageObjectHelper.displayable_name(message_object)}")
        zip.write(message_object.content)
      end
    end

    def prepare_print_objects(zip)
      objects.each do |message_object|
        if message_object.nested_message_objects.any?
          prepare_nested_print_objects(zip, message_object)
        else
          next unless message_object.downloadable_as_pdf?

          pdf_content = message_object.prepare_pdf_visualization

          raise StandardError, "Unable to prepare PDF visualization for MessageObject ID #{message_object.id}" unless pdf_content

          zip.put_next_entry(MessageObjectHelper.pdf_name(message_object))
          zip.write(pdf_content)
        end
      end
    end

    def prepare_nested_print_objects(zip, message_object)
      message_object.nested_message_objects.each do |nested_message_object|
        next unless nested_message_object.pdf? || nested_message_object.downloadable_as_pdf?

        if nested_message_object.pdf?
          pdf_content = nested_message_object.content
        else
          pdf_content = nested_message_object.prepare_pdf_visualization
          raise StandardError, "Unable to prepare PDF visualization for MessageObject ID #{nested_message_object.id}" unless pdf_content
        end

        zip.put_next_entry(MessageObjectHelper.pdf_name(nested_message_object))
        zip.write(pdf_content)
      end
    end
  end
end
