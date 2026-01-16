# == Schema Information
#
# Table name: boxes
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  color       :enum
#  export_name :string           not null
#  name        :string           not null
#  settings    :jsonb            not null
#  short_name  :string
#  syncable    :boolean          default(TRUE), not null
#  type        :string
#  uri         :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  tenant_id   :bigint           not null
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

    Box.create!(params.except(:api_connection, :api_connection_id).merge(type: 'Fs::Box', api_connections: [api_connection]))
  end

  def sync
    return unless active?

    boxes_api_connections.group_by { |boxes_api_connection| boxes_api_connection.settings_delegate_id }.each do |settings_delegate_id, boxes_api_connections|
      ::Fs::SyncBoxJob.set(job_context: :asap).perform_later(self, api_connection: boxes_api_connections.first.api_connection)
    end
  end

  def single_recipient?
    true
  end

  store_accessor :settings, :dic, prefix: true
  store_accessor :settings, :subject_id, prefix: true
  store_accessor :settings, :is_subject_c_reg, prefix: true
end
