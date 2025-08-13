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

  DEFAULT_TEMPLATE = "{{ schranka.nazov }}/vlakno-{{ vlakno.id }}/sprava-{{ sprava.id }}/{{ subor.nazov }}"

  REPLACEMENT_MAPPINGS = {
    "{{ schranka.nazov }}" => -> (o) { o.message.thread.box.name },
    "{{ schranka.oficialny_nazov }}" => -> (o) { o.message.thread.box.official_name },
    "{{ schranka.dic }}" => -> (o) { o.message.thread.box.settings["dic"] },
    "{{ vlakno.id }}" => ->(o) { o.message.thread.id },
    "{{ vlakno.obdobie }}" => ->(o) { o.message.thread.metadata["period"] if o.message.thread.metadata&.dig("period") },
    "{{ vlakno.formular }}" => ->(o) { form_name(o) },
    "{{ vlakno.formular_bez_verzie }}" => ->(o) { form_name(o, include_version: false) },
    "{{ vlakno.datum_podania }}" => ->(o) { o.message.thread.messages.outbox.first.delivered_at&.to_date },
    "{{ sprava.id }}" => ->(o) { o.message.id },
    "{{ subor.nazov }}" => ->(o) { o.name }
  }.freeze

  def start
    user.notifications.create!(
      type: Notifications::ExportStarted,
      export: self
    )
    ExportJob.perform_later(self)
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

    out.sub(/^\/+/, '')
  end

  def self.form_name(object, include_version: true)
    Fs::Form.find_by(id: object.message.thread.metadata&.dig("fs_form_id"))&.short_name(include_version: include_version)
  end

  def storage_path
    File.join(Rails.root, "storage", "exports", file_name)
  end

  def file_name
    "#{user.tenant.id}/govbox-pro-export-#{created_at.to_date}.zip"
  end

  private

  def set_default_template
    self.settings ||= {}
    self.settings['templates'] ||= {}
    self.settings['templates']['default'] = DEFAULT_TEMPLATE if settings.dig('templates', 'default').blank?
  end
end
