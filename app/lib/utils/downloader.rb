module Utils
  class Downloader
    def download(url)
      response = Faraday.get(url)
      raise StandardError, "Unexpected response status: #{response.status} for url: #{url}" if response.status != 200

      if response.body.force_encoding('UTF-8').valid_encoding?
        response.body
      elsif response.body.force_encoding('UTF-16').valid_encoding?
        response.body.force_encoding('UTF-16').encode!('UTF-8')
      else
        raise StandardError "Unexpected encoding for url: #{url}"
      end
    end

    def get(url)
      Faraday.get(url)
    end
  end
end
