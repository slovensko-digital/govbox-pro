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
    "{{ schranka.dic }}" => -> (o) { o.message.thread.box.settings["dic"] },
    "{{ vlakno.id }}" => ->(o) { o.message.thread.id },
    "{{ vlakno.obdobie }}" => ->(o) { o.message.thread.metadata["period"] if o.message.thread.metadata&.dig("period") },
    "{{ vlakno.formular }}" => ->(o) { Fs::Form.find_by_id(o.message.thread.metadata["fs_form_id"])&.slug if o.message.thread.metadata&.dig("fs_form_id") },
    "{{ vlakno.datum_podania }}" => ->(o) { o.message.thread.messages.outbox.first.delivered_at&.to_date  },
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
    template = settings.dig("templates", message_object.message.message_type).presence || settings.dig("templates", "default").presence || DEFAULT_TEMPLATE
    out = template.dup
    REPLACEMENT_MAPPINGS.map do |key, value_function|
      out.gsub!(key) { value_function.call(message_object) }
    end

    out
  end

  def storage_path
    File.join(Rails.root, "storage", "exports", "#{user.tenant.id}/#{id}.zip")
  end

  private

  def set_default_template
    self.settings ||= {}
    self.settings['templates'] ||= {}
    self.settings['templates']['default'] = DEFAULT_TEMPLATE if settings.dig('templates', 'default').blank?
  end
end
