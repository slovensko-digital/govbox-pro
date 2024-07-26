# == Schema Information
#
# Table name: api_connections
#
#  id                    :bigint           not null, primary key
#  api_token_private_key :string           not null
#  obo                   :uuid
#  settings              :jsonb
#  sub                   :string           not null
#  type                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
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

  def destroy_with_box?
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
    fs_api.get_subjects.each do |subject|
      box = Fs::Box.find_or_initialize_by(
        tenant: tenant,
        api_connection: self,
        settings: {
          dic: subject["dic"],
          subject_id: subject["subject_id"],
          message_drafts_import_enabled: Fs::Box::DISABLED_MESSAGE_DRAFTS_IMPORT_KEYWORDS.none? { |keyword| subject["name"].include?(keyword) }
        }
      ).tap do |box|
        box.name = "FS " + subject["name"]
        box.short_name ||= generate_short_name_from_name(subject["name"])
        box.uri = "dic://sk/#{subject['dic']}"
        box.syncable = false
      end

      count += 1 if box.new_record? && box.save

      box.save
    end

    count
  end

  private

  def generate_short_name_from_name(name)
    generated_base_name = "FS" + name.split.map(&:first).join.upcase

    return generated_base_name unless tenant.boxes.where(short_name: generated_base_name).present?

    1.step do |i|
      generated_short_name = "#{generated_base_name}#{i}"

      return generated_short_name unless tenant.boxes.where(short_name: generated_short_name).present?
    end
  end
end
