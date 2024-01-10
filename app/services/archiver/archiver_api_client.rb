class Archiver::ArchiverApiClient
  def self.api
    Archiver::ArchiverApi.new(ENV['ARCHIVER_API_URL'])
  end
end
