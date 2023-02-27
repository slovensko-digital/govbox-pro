require 'jwt'

class GovboxApi
  def initialize(sub, url: ENV['GB_API_URL'])
    @sub = sub
    @api_token_private_key = load_api_token_private_key
    @url = url
  end

  def receive_and_save_to_outbox(data)
    response = RestClient.post(
      url = "#{@url}/api/sktalk/receive_and_save_to_outbox",
      {
        data: data.to_json
      },
      {
        "Authorization": authorization_payload,
        "Content-Type": "application/vnd.sktalk+json;type=SkTalk"
      }
    )

    result = JSON.parse(response.body)
    receive_and_save_to_outbox_successful?(result)
  end

  private

  def load_api_token_private_key
    private_key_path = Rails.root.join('security', "govbox_api_#{ENV['GB_API_ENV']}.pem").to_s
    OpenSSL::PKey::RSA.new(File.read(private_key_path))
  end

  def authorization_payload
    "Bearer #{token}"
  end

  def token
    JWT.encode({ sub: @sub, exp: 5.minutes.from_now.to_i, jti: SecureRandom.uuid }, @api_token_private_key, 'RS256')
  end

  def receive_and_save_to_outbox_successful?(response)
    response['receive_result'] == 0 && response['save_to_outbox_result'] == 0
  end
end
