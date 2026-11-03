require 'axlsx'

class ExportJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  REPLACEMENT_MAPPINGS = {
    "{{ schranka.nazov }}" => -> (o) { sanitize_path_component(o.message.thread.box.name) },
    "{{ schranka.oficialny_nazov }}" => -> (o) { sanitize_path_component(o.message.thread.box.official_name) },
    "{{ schranka.export_nazov }}" => -> (o) { sanitize_path_component(o.message.export_metadata_box_name.presence || o.message.thread.box.export_name) },
    "{{ schranka.dic }}" => -> (o) { o.message.thread.box.settings["dic"] },
    "{{ vlakno.id }}" => ->(o) { o.message.thread.id },
    "{{ vlakno.nazov }}" => ->(o) { sanitize_path_component(o.message.thread.title) },
    "{{ vlakno.obdobie }}" => ->(o) { sanitize_path_component(o.message.thread.metadata["period"]) if o.message.thread.metadata&.dig("period") },
    "{{ vlakno.formular }}" => ->(o) { sanitize_path_component(form_name(o)) },
    "{{ vlakno.formular_bez_verzie }}" => ->(o) { sanitize_path_component(form_name(o, include_version: false)) },
    "{{ vlakno.datum_podania }}" => ->(o) { o.message.thread.messages.outbox&.first&.delivered_at&.to_date },
    "{{ vlakno.datum_dorucenia }}" => ->(o) { o.message.delivered_at.to_date },
    "{{ sprava.id }}" => ->(o) { o.message.id },
    "{{ subor.nazov }}" => ->(o) { sanitize_path_component(MessageObjectHelper.displayable_name(o)) }
  }.freeze

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
      each_export_object(export) do |object|
        prepare_original_object(object, export: export, zip: zip, file_paths: file_paths) if export.settings_object.originals
        prepare_pdf_object(object, export: export, zip: zip, file_paths: file_paths)

        EventBus.publish(:message_object_downloaded, object)
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
    file_path = export_object_filepath(object, export: export, other_file_names: file_paths)
    return unless file_path

    zip.put_next_entry(file_path)
    zip.write(object.content)
    file_paths << file_path
  end

  def prepare_pdf_object(object, export:, zip:, file_paths:)
    pdf_objects(object, export: export).each do |pdf_object|
      pdf_content = pdf_object.pdf? ? pdf_object.content : pdf_visualization(pdf_object)

      file_path = export_object_filepath(object, export: export, other_file_names: file_paths, pdf: true)
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

  def preview_filepaths(export, message_threads:)
    paths = {}
    file_names = []
    each_export_object(export, message_threads: message_threads) do |object|
      paths[object.id] = export_object_filepaths(object, export: export, other_file_names: file_names)
      file_names.concat(paths[object.id])
    end
    paths
  end

  def export_object_filepaths(object, export:, other_file_names: [])
    paths = []
    paths << export_object_filepath(object, export: export, other_file_names: other_file_names) if export.settings_object.originals
    pdf_objects(object, export: export).each do
      paths << export_object_filepath(object, export: export, pdf: true, other_file_names: other_file_names + paths.compact)
    end
    paths.compact
  end

  def export_object_filepath(object, export:, pdf: false, other_file_names: [])
    thread = object.message.thread
    form = thread.box.export_form(thread)&.slug
    type = object.message.message_type
    settings = export.settings
    default_template = settings.dig("templates", "default").presence || Export::DEFAULT_TEMPLATE

    if settings.dig('by_type', type).present?
      template = settings.dig("templates", type).presence || default_template
    elsif settings.dig('by_form', form).present?
      template = settings.dig("templates", form).presence || default_template
    elsif settings['default'].present?
      template = default_template
    else
      return nil
    end

    out = template.dup
    REPLACEMENT_MAPPINGS.each do |key, value_function|
      out.gsub!(key) { value_function.call(object) }
    end

    out.gsub!(/\.\.\//, '')
    out = out.sub(/^\/+/, '')
    original_extension = File.extname(MessageObjectHelper.displayable_name(object))
    extension = pdf ? '.pdf' : original_extension
    path_without_extension = out.delete_suffix(original_extension)
    path = "#{path_without_extension}#{extension}"
    return path unless path.in?(other_file_names)

    matches_count = other_file_names.count { |name| /#{Regexp.escape(path_without_extension)}( \(\d+\))?#{Regexp.escape(extension)}/ =~ name }
    "#{path_without_extension} (#{matches_count})#{extension}"
  end

  def self.form_name(object, include_version: true)
    thread = object.message.thread
    thread.box.export_form(thread)&.short_name(include_version: include_version)
  end

  def self.sanitize_path_component(value)
    value.to_s.gsub("/", "-").gsub("\\", "-")
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

  private

  def each_export_object(export, message_threads: export.message_threads)
    return unless export.settings['messages']

    message_threads.each do |thread|
      export.filtered_messages(thread).includes(:thread).sort_by(&:delivered_at).each do |message|
        message.objects.each { |object| yield object }
      end
    end
  end

  def pdf_objects(object, export:)
    return [] unless export.settings['pdf']
    return [] if export.settings_object.originals && object.pdf?

    objects = object.nested_message_objects.presence || [object]
    objects.select { |pdf_object| pdf_object.pdf? || pdf_object.downloadable_as_pdf? }
  end
end
