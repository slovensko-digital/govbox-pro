class Api::SiteAdmin::Stats::Tenant
  include ActiveModel::API
  attr_accessor :from, :to

  validates :from, :to, presence: true

  def initialize(params)
    @from = Time.zone.parse(params[:from]) if params[:from]
    @to = Time.zone.parse(params[:to]) if params[:to]
  end
end
