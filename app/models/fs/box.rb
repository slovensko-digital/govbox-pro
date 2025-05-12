# == Schema Information
#
# Table name: boxes
#
#  id                :bigint           not null, primary key
#  color             :enum
#  name              :string           not null
#  settings          :jsonb
#  short_name        :string
#  syncable          :boolean          default(TRUE), not null
#  type              :string
#  uri               :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  api_connection_id :bigint
#  tenant_id         :bigint           not null
#
class Fs::Box < Box
  DISABLED_MESSAGE_DRAFTS_IMPORT_KEYWORDS = ['(oblasť SPD)']

  before_create { self.syncable = tenant.feature_enabled?(:fs_sync) }

  validates_uniqueness_of :short_name, scope: [:tenant_id]
  validates_uniqueness_of :name, scope: [:tenant_id, :uri]

  def self.policy_class
    BoxPolicy
  end

  def self.create_with_api_connection!(params)
    if params[:api_connection]
      api_connection = Fs::ApiConnection.create!(params[:api_connection].merge(tenant_id: params[:tenant_id]))
    elsif params[:api_connection_id]
      api_connection = Fs::ApiConnection.find(params[:api_connection_id])
    end
    raise ArgumentError, "Api connection must be provided" unless api_connection

    api_connection.boxes.create!(params.except(:api_connection).merge(type: 'Fs::Box'))
  end

  def sync
  end

  def single_recipient?
    true
  end

  store_accessor :settings, :dic, prefix: true
  store_accessor :settings, :subject_id, prefix: true
  store_accessor :settings, :delegate_id, prefix: true
  store_accessor :settings, :is_subject_c_reg, prefix: true
end
