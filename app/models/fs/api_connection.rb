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

  def boxify
    count = 0
    fs_api = FsEnvironment.fs_client.api(api_connection: self)

    Fs::Box.transaction do
      deactivate_connections!

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
            box_api_connection.settings_active = true
            box_api_connection.save
          end
        end
      end
    end

    count
  end

  private

  def deactivate_connections!
    boxes_api_connections.find_each { |connection| connection.update!(settings_active: false) }
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
