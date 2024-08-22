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

  USER_INITIATED_SYNC_JOB_QUEUE_NAME = :highest_priority

  def self.policy_class
    BoxPolicy
  end

  validates_uniqueness_of :name, :short_name, :uri, scope: :tenant_id

  store_accessor :settings, :obo, prefix: true

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
    Govbox::SyncBoxJob.set(queue: USER_INITIATED_SYNC_JOB_QUEUE_NAME).perform_later(self)
  end
end
