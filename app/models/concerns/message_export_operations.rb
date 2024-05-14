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

    private

    def prepare_original_objects(zip)
      objects.each do |message_object|
        zip.put_next_entry("na_pravne_ucely/#{MessageObjectHelper.displayable_name(message_object)}")
        zip.write(message_object.content)
      end
    end

    def prepare_print_objects(zip)
      objects.each do |message_object|
        pdf_content = message_object.prepare_pdf_visualization

        next unless pdf_content

        zip.put_next_entry("na_tlac/#{MessageObjectHelper.pdf_name(message_object)}")
        zip.write(pdf_content)
      end
    end
  end
end
