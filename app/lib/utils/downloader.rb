module Utils
  class Downloader
    def download(url)
      response = Faraday.get(url)
      raise StandardError, "Unexpected response status: #{response.status} for url: #{url}" if response.status != 200
      response.body
    end

    def get(url)
      Faraday.get(url)
    end
  end
end
