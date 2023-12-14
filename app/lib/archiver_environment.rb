module ArchiverEnvironment
  def self.archiver_client
    @archiver_client ||= Archiver::ArchiverApiClient.new
  end
end
