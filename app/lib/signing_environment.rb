module SigningEnvironment
  def self.signing_client
    @signing_client ||= Agp::AgpApiClient.new
  end
end
