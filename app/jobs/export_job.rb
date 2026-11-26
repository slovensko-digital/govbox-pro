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
    cleanup_parts(export, reset_finalized: true)
    FileUtils.rm_f("#{export.storage_path}.tmp")
    export.user.notifications.create!(type: Notifications::ExportFailed, export: export)
  end

  queue_as :default

  THREADS_PER_BATCH = 25

  def perform(export, offset: 0, batch_size: THREADS_PER_BATCH)
    return finalize_export(export) if export.finalized_at?

    if export.settings.dig("messages")
      thread_ids = export.message_thread_ids.uniq.sort
      batch_ids = thread_ids[offset, batch_size] || []
      build_part(export, batch_ids, offset) if batch_ids.any?

      return ExportJob.set(job_context: :medium).perform_later(export, offset: offset + batch_size, batch_size: batch_size) if offset + batch_size < thread_ids.size
    end

    finalize_export(export)
  end

  def write_object(object, export:, zip:, used_paths:, publish_event: true)
    written = false
    each_object_file(object, export: export, used_paths: used_paths) do |path, source, render_pdf|
      content = render_pdf ? pdf_visualization(source) : source.content
      zip.put_next_entry(path)
      zip.write(content)
      written = true
    end
    EventBus.publish(:message_object_downloaded, object) if written && publish_event
    written
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

  def parts_dir(export)
    Rails.root.join("storage", "exports", "tmp", "export-#{export.id}").to_s
  end

  def part_path(export, offset)
    File.join(parts_dir(export), "part-#{offset}.zip")
  end

  def cleanup_parts(export, reset_finalized: false)
    FileUtils.rm_rf(parts_dir(export))
    updates = {}
    updates[:parts] = {} if export.parts.any?
    updates[:finalized_at] = nil if reset_finalized && export.finalized_at?
    export.update_columns(updates.merge(updated_at: Time.current)) if updates.any?
  end

  def build_part(export, batch_ids, offset)
    part_path = part_path(export, offset)
    tmp_path = "#{part_path}.tmp"
    FileUtils.mkdir_p(File.dirname(part_path))

    used_paths = reserved_paths(export)
    export.parts.each do |part_offset, part|
      used_paths.merge(part["file_paths"] || []) if part_offset.to_i < offset
    end
    seed_count = used_paths.size
    object_ids = []

    ::Zip::OutputStream.open(tmp_path) do |zip|
      each_export_object(export, message_threads: export.message_threads.where(id: batch_ids)) do |object|
        object_ids << object.id if write_object(object, export: export, zip: zip, used_paths: used_paths, publish_event: false)
      end
    end

    FileUtils.mv(tmp_path, part_path)

    export.update_columns(
      parts: export.parts.merge(
        offset.to_s => {
          "object_ids" => object_ids.uniq,
          "file_paths" => used_paths.to_a.drop(seed_count)
        }
      ),
      updated_at: Time.current
    )
  end

  def finalize_export(export)
    unless export.finalized_at?
      final_tmp_path = "#{export.storage_path}.tmp"
      FileUtils.mkdir_p(File.dirname(export.storage_path))

      ::Zip::OutputStream.open(final_tmp_path) do |zip|
        export.parts.keys.map(&:to_i).sort.each do |offset|
          ::Zip::File.open(part_path(export, offset)) do |part_zip|
            part_zip.each do |entry|
              zip.put_next_entry(entry.name)
              zip.write(entry.get_input_stream.read)
            end
          end
        end

        prepare_summary(export: export, zip: zip) if export.settings.dig("summary")
      end

      FileUtils.mv(final_tmp_path, export.storage_path)
      export.update_columns(finalized_at: Time.current, updated_at: Time.current)
    end

    publish_download_events(export) if export.settings.dig("messages")
    cleanup_parts(export)

    started_id = export.user.notifications.where(export: export, type: "Notifications::ExportStarted").maximum(:id) || 0
    unless export.user.notifications.exists?(export: export, type: "Notifications::ExportFinished", id: (started_id + 1)..)
      Notifications::ExportFinished.create!(user: export.user, export: export)
    end
  end

  def publish_download_events(export)
    remaining = export.parts.dup

    remaining.keys.map(&:to_i).sort.each do |offset|
      key = offset.to_s
      object_ids = remaining.dig(key, "object_ids") || []

      MessageObject.where(id: object_ids).find_each do |object|
        EventBus.publish(:message_object_downloaded, object)
      end

      remaining.delete(key)
      export.update_columns(parts: remaining, updated_at: Time.current)
    end
  end
end
