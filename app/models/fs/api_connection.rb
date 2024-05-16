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
      unless Fs::Box.where("settings @> ?", {dic: subject["dic"], subject_id: subject["subject_id"]}.to_json).count > 0
        box = Fs::Box.new(
          settings_dic: subject["dic"],
          settings_subject_id: subject["subject_id"],
          api_connection: self,
          tenant: tenant,
          name: "FS " + subject["name"],
          short_name: "FS" + subject["name"].split.map(&:first).join.upcase,
          uri: "dic://sk/#{subject['dic']}",
          syncable: false
        )
        count += 1 if box.save
      end
    end

    count
  end
end
