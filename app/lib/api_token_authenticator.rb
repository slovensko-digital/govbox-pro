class ApiTokenAuthenticator
  MAX_EXP_IN = 5.minutes
  JTI_PATTERN = /\A[0-9a-z\-_]{32,256}\z/i

  def initialize(public_key_reader:, return_handler:)
    @public_key_reader = public_key_reader
    @return_handler = return_handler
  end

  def verify_token(token)
    options = {
      algorithm: 'RS256',
      verify_jti: -> (jti) { jti =~ JTI_PATTERN },
    }

    key_finder = -> (_, payload) do
      @public_key_reader.call(payload['sub'])
    rescue
      raise JWT::InvalidSubError
    end

    payload, _ = JWT.decode(token, nil, true, options, &key_finder)
    sub, exp, jti = payload['sub'], payload['exp'], payload['jti']

    raise JWT::ExpiredSignature unless exp.is_a?(Integer)
    raise JWT::InvalidPayload if exp > (Time.now + MAX_EXP_IN).to_i

    @return_handler.call(sub)
  end
end
