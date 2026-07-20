# == Schema Information
#
# Table name: exports
#
#  id                 :bigint           not null, primary key
#  message_thread_ids :integer          default([]), not null, is an Array
#  settings           :jsonb            not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint           not null
#
class Export < ApplicationRecord
  belongs_to :user
  before_save :set_default_template
  before_validation :normalize_settings
  validate :at_least_one_export_option, unless: :new_record?
  validate :delivered_at_range_valid, unless: :new_record?

  DEFAULT_TEMPLATE = "{{ schranka.export_nazov }}/vlakno-{{ vlakno.id }}/sprava-{{ sprava.id }}/{{ subor.nazov }}"

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

  def start
    user.notifications.create!(
      type: Notifications::ExportStarted,
      export: self
    )
    ExportJob.set(job_context: :medium).perform_later(self)
  end

  def message_threads
    MessageThread.where(id: message_thread_ids)
  end

  def export_object_filepath(message_object)
    thread = message_object.message.thread
    form = Fs::Form.find_by(id: thread.metadata&.dig("fs_form_id"))&.slug
    type = message_object.message.message_type

    default_template = settings.dig("templates", "default").presence || DEFAULT_TEMPLATE

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
    REPLACEMENT_MAPPINGS.map do |key, value_function|
      out.gsub!(key) { value_function.call(message_object) }
    end

    out.gsub!(/\.\.\//, '')
    out.sub(/^\/+/, '')
  end

  def self.form_name(object, include_version: true)
    Fs::Form.find_by(id: object.message.thread.metadata&.dig("fs_form_id"))&.short_name(include_version: include_version)
  end

  def self.sanitize_path_component(value)
    value.to_s.gsub("/", "-").gsub("\\", "-")
  end

  def storage_path
    File.join(Rails.root, "storage", "exports", file_name)
  end

  def file_name
    old_name = "#{user.tenant.id}/govbox-pro-export-#{created_at.to_date}.zip" # Old naming logic
    new_name = "#{user.tenant.id}/govbox-pro-export-##{id}-#{created_at.to_date}.zip"
    File.exist?(File.join(Rails.root, "storage", "exports", old_name)) ? old_name : new_name
  end

  def filtered_messages(message_thread)
    messages = case settings["message_direction"]
               when "outbox" then message_thread.messages.outbox
               when "inbox"  then message_thread.messages.inbox
               else               message_thread.messages
               end

    from = ActiveModel::Type::Date.new.cast(settings["delivered_at_from"])
    to   = ActiveModel::Type::Date.new.cast(settings["delivered_at_to"])
    messages = messages.where("delivered_at >= ?", from.beginning_of_day) if from
    messages = messages.where("delivered_at <= ?", to.end_of_day) if to
    messages
  end

  private

  def set_default_template
    self.settings ||= {}
    self.settings['templates'] ||= {}
    self.settings['templates']['default'] = DEFAULT_TEMPLATE if settings.dig('templates', 'default').blank?
  end

  def at_least_one_export_option
    errors.add(:base, I18n.t('activerecord.errors.models.export.attributes.base.empty_selection')) unless settings['summary'] || settings['messages']
  end

  def normalize_settings
    self.settings ||= {}
    %w[summary messages pdf default].each do |flag|
      settings[flag] = ActiveModel::Type::Boolean.new.cast(settings[flag]) if settings.key?(flag)
    end
    settings["message_direction"] = settings["message_direction"].presence&.then { |v|
      %w[all inbox outbox].include?(v) ? v : "all"
    } || "all"
    settings["delivered_at_from"] = ActiveModel::Type::Date.new.cast(settings["delivered_at_from"]) if settings.key?("delivered_at_from")
    settings["delivered_at_to"]   = ActiveModel::Type::Date.new.cast(settings["delivered_at_to"])   if settings.key?("delivered_at_to")
  end

  def delivered_at_range_valid
    from = settings["delivered_at_from"]
    to   = settings["delivered_at_to"]
    return unless from.is_a?(Date) && to.is_a?(Date)
    errors.add(:base, I18n.t('activerecord.errors.models.export.attributes.base.invalid_date_range')) if from > to
  end
end
