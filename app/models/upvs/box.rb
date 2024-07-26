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

  validate :validate_settings_obo

  after_initialize :initialize_defaults, :if => :new_record?

  def self.create_with_api_connection!(params)
    if params[:api_connection]
      api_connection = Govbox::ApiConnection.create!(params[:api_connection])
    elsif params[:api_connection_id]
      api_connection = ApiConnection.find(params[:api_connection_id])
    end
    raise ArgumentError, "Api connection must be provided" unless api_connection

    api_connection.boxes.create!(params.except(:api_connection).merge(type: 'Upvs::Box'))
  end

  def sync
    Govbox::SyncBoxJob.perform_later(self)
  end

  private
  def initialize_defaults
    self.settings_obo ||= nil
  end

  def validate_settings_obo
    errors.add(:settings_obo, "OBO must be in UUID format") if settings_obo.present? && !settings_obo.match?(Utils::UUID_PATTERN)
  end
end
