require 'axlsx'

class ExportJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  SUMMARY_PATH = 'sumar.xlsx'

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
    used_paths = reserved_paths(export)

    export_content = ::Zip::OutputStream.write_buffer do |zip|
      each_export_object(export) do |object|
        write_object(object, export: export, zip: zip, used_paths: used_paths)
      end

      prepare_summary(export: export, zip: zip) if export.settings.dig("summary")
    end

    FileStorage.new.store("exports", export.file_name, export_content.string.force_encoding("UTF-8"))

    export.user.notifications.create!(
      type: Notifications::ExportFinished,
      export: export
    )
  end

  def write_object(object, export:, zip:, used_paths:)
    written = false
    each_object_file(object, export: export, used_paths: used_paths) do |path, source, render_pdf|
      content = render_pdf ? pdf_visualization(source) : source.content
      zip.put_next_entry(path)
      zip.write(content)
      written = true
    end
    EventBus.publish(:message_object_downloaded, object) if written
  end

  def pdf_visualization(object)
    object.prepare_pdf_visualization || raise(PdfVisualizationFailed, pdf_visualization_failure(object))
  end

  def pdf_visualization_failure(object)
    "Unable to prepare PDF visualization for #{object.class.name} ID #{object.id}"
  end

  def preview_filepaths(export, message_threads:)
    paths = {}
    used_paths = reserved_paths(export)
    each_export_object(export, message_threads: message_threads) do |object|
      paths[object] = each_object_file(object, export: export, used_paths: used_paths).map { |path, _, _| path }
    end
    paths
  end

  def export_object_filepath(object, export:, pdf: false, other_file_names: [])
    thread = object.message.thread
    type = object.message.message_type
    settings = export.settings
    form = thread.box.export_form(thread)&.slug if settings['by_form'].present?
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
    base = out.sub(/^\/+/, '')
    original_extension = File.extname(MessageObjectHelper.displayable_name(object))
    extension = pdf ? '.pdf' : original_extension
    path_without_extension = base.delete_suffix(original_extension)
    path = "#{path_without_extension}#{extension}"
    suffix = 0
    while other_file_names.include?(path)
      suffix += 1
      path = "#{path_without_extension} (#{suffix})#{extension}"
    end
    path
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

      zip.put_next_entry(SUMMARY_PATH)
      zip.write(p.to_stream.read)
    end
  end

  private

  def reserved_paths(export)
    export.settings['summary'] ? Set[SUMMARY_PATH] : Set.new
  end

  def each_object_file(object, export:, used_paths:)
    return enum_for(__method__, object, export: export, used_paths: used_paths) unless block_given?

    originals = export.settings_object.originals
    if originals
      path = export_object_filepath(object, export: export, other_file_names: used_paths)
      return unless path
      yield path, object, false
      used_paths << path
    end
    return unless export.settings['pdf']
    return if originals && object.pdf?

    sources = object.nested_message_objects.sort_by(&:id).presence || [object]
    sources.each do |source|
      next unless source.pdf? || source.downloadable_as_pdf?

      path = export_object_filepath(object, export: export, pdf: true, other_file_names: used_paths)
      next unless path
      yield path, source, !source.pdf?
      used_paths << path
    end
  end

  def each_export_object(export, message_threads: export.message_threads)
    return unless export.settings['messages']

    message_threads.reorder(:id).each do |thread|
      export.filtered_messages(thread).includes(:objects).order(:delivered_at, :id).each do |message|
        message.objects.sort_by(&:id).each { |object| yield object }
      end
    end
  end
end
