class Api::SiteAdmin::Stats::Tenant
  include ActiveModel::API
  attr_accessor :from, :to

  validates :from, :to, presence: true

  def initialize(params)
    @from = Time.zone.parse(params.require(:from))
    @to = Time.zone.parse(params.require(:to))
  end
end
