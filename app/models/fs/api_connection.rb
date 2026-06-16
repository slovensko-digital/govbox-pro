# == Schema Information
#
# Table name: api_connections
#
#  id                    :bigint           not null, primary key
#  api_token_private_key :string           not null
#  custom_name           :string
#  obo                   :uuid
#  settings              :jsonb
#  sub                   :string           not null
#  type                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  owner_id              :bigint
#  tenant_id             :bigint
#
class Fs::ApiConnection < ::ApiConnection
  validates :tenant_id, presence: true
  encrypts :settings

  store_accessor :settings, :username, prefix: true
  store_accessor :settings, :password, prefix: true
  store_accessor :settings, :authentication_failed_at, prefix: true

  def box_obo(box)
    raise "OBO not allowed!" if invalid_obo?(box)
    obo.presence
  end

  def destroy_with_box?(box)
    false
  end

  def validate_box(box)
  end

  def editable?
    true
  end

  def destroyable?
    boxes.empty?
  end

  def fs_type?
    true
  end

  def upvs_type?
    false
  end

  def authentication_failed?
    settings_authentication_failed_at.present?
  end

  def mark_authentication_failed!
    update!(settings_authentication_failed_at: Time.current)
    create_authentication_failed_sticky_notes
  end

  def clear_authentication_failure!
    update!(settings_authentication_failed_at: nil)
    dismiss_authentication_failed_sticky_notes
  end

  def credentials_configured?
    settings_username.present? && settings_password.present?
  end

  def needs_credentials_setup?
    !credentials_configured? || authentication_failed?
  end

  def boxify
    count = 0
    fs_api = FsEnvironment.fs_client.api(api_connection: self)
    processed_connection_ids = []

    Fs::Box.transaction do
      fs_api.get_subjects.each do |subject|
        Fs::Box.with_advisory_lock!("boxify-#{tenant_id}", transaction: true, timeout_seconds: 10) do
          boxes = Fs::Box.where(tenant: tenant).where("settings @> ?", {dic: subject["dic"], subject_id: subject["subject_id"]}.to_json)
          box = boxes.first unless boxes.count > 1

          unless box
            box = Fs::Box.new(
              tenant: tenant,
              settings: {
                dic: subject["dic"],
                subject_id: subject["subject_id"],
                message_drafts_import_enabled: Fs::Box::DISABLED_MESSAGE_DRAFTS_IMPORT_KEYWORDS.none? { |keyword| subject["name"].include?(keyword) }
              },
              api_connections: [self]
            )
          end

          box.name = "FS " + subject["name"]
          box.short_name ||= generate_short_name_from_name(subject["name"])
          box.uri = "dic://sk/#{subject['dic']}"
          box.settings_is_subject_c_reg ||= subject["is_subject_c_reg"]
          box.active = true

          count += 1 if box.new_record? && box.save

          box.save

          box.boxes_api_connections.find_or_create_by(api_connection: self).tap do |box_api_connection|
            box_api_connection.settings_delegate_id = subject["delegate_id"]
            box_api_connection.active = true
            box_api_connection.save

            processed_connection_ids << box_api_connection.id
          end
        end
      end

      deactivate_stale_connections(processed_connection_ids)
    end

    clear_authentication_failure! if authentication_failed?

    count
  end

  private

  def deactivate_stale_connections(processed_connection_ids)
    stale = boxes_api_connections.where.not(id: processed_connection_ids)
    affected_box_ids = stale.pluck(:box_id)
    stale.update_all(active: false)

    Fs::Box.where(id: affected_box_ids).find_each(&:update_active_state_from_connections)
  end

  def create_authentication_failed_sticky_notes
    tenant.admin_group.users.find_each do |user|
      sticky_note = user.sticky_note || user.build_sticky_note
      sticky_note.update!(
        note_type: "fs_authentication_failed",
        data: {
          "api_connection_id" => id,
          "api_connection_name" => name,
          "tenant_id" => tenant_id
        }
      )
    end
  end

  def dismiss_authentication_failed_sticky_notes
    tenant.admin_group.users.find_each do |user|
      note = user.sticky_note
      note.destroy if note&.note_type == "fs_authentication_failed" && note.data&.dig("api_connection_id") == id
    end
  end

  def generate_short_name_from_name(name)
    generated_base_name = "FS" + name.split.map(&:first).join.upcase

    return generated_base_name unless tenant.boxes.where(short_name: generated_base_name).present?

    1.step do |i|
      generated_short_name = "#{generated_base_name}#{i}"

      return generated_short_name unless tenant.boxes.where(short_name: generated_short_name).present?
    end
  end
end
