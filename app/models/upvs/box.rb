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
class Upvs::Box < Box
  def self.policy_class
    BoxPolicy
  end

  store_accessor :settings, :obo, prefix: true

  validates_uniqueness_of :name, :short_name, :uri, scope: :tenant_id

  validate :validate_settings_obo

  normalizes :settings, with: -> (settings) {
    settings['obo'] = settings['obo'].presence
    settings
  }

  def self.create_with_api_connection!(params)
    if params[:api_connection]
      api_connection = Govbox::ApiConnection.create!(params[:api_connection])
    elsif params[:api_connection_id]
      api_connection = ApiConnection.find(params[:api_connection_id])
    end
    raise ArgumentError, "Api connection must be provided" unless api_connection

    Box.create!(params.except(:api_connection).merge(type: 'Upvs::Box', api_connections: [api_connection]))
  end

  def sync
    Govbox::SyncBoxJob.set(job_context: :asap).perform_later(self)
  end

  def single_recipient?
    false
  end

  private

  def validate_settings_obo
    return unless settings_obo.present?
    errors.add(:settings_obo, "OBO must be in UUID format") unless settings_obo.match?(Utils::UUID_PATTERN)
  end
end
