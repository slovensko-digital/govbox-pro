require 'test_helper'

class ApiTokenAuthenticatorTest < ActiveSupport::TestCase
  setup do
    @sub = 1
    @key_pair = OpenSSL::PKey::RSA.new(512)
    @public_key_reader = ->(s) { s == @sub ? @key_pair.public_key : raise }
    @return_handler = ->(s) { s }
    @api_token_authenticator = ApiTokenAuthenticator.new(
      public_key_reader: @public_key_reader,
      return_handler: @return_handler
    )
  end

  test '#verify_token returns SUB value' do
    token = generate_token(sub: @sub, key_pair: @key_pair)
    assert_equal @sub, @api_token_authenticator.verify_token(token)
  end

  test '#verify_token verifies format' do
    assert_raises(JWT::DecodeError) { @api_token_authenticator.verify_token(nil) }
    assert_raises(JWT::DecodeError) { @api_token_authenticator.verify_token('NON-JWT') }
  end

  test '#verify_token verifies algorithm' do
    token = JWT.encode({ sub: @sub }, 'KEY', 'HS256')
    assert_raises(JWT::IncorrectAlgorithm) { @api_token_authenticator.verify_token(token) }
  end

  test '#verify_token verifies signature' do
    token = JWT.encode({ sub: @sub }, OpenSSL::PKey::RSA.new(512), 'RS256')
    assert_raises(JWT::VerificationError) { @api_token_authenticator.verify_token(token) }
  end

  test '#verify_token verifies SUB claim presence' do
    token = generate_token(sub: nil)
    assert_raises(JWT::InvalidSubError) { @api_token_authenticator.verify_token(token) }
  end

  test 'verifies SUB claim value' do
    token = generate_token(sub: 'unknown-subject')
    assert_raises(JWT::InvalidSubError) { @api_token_authenticator.verify_token(token) }
  end

  test 'verifies EXP claim presence' do
    token = generate_token(exp: nil)
    assert_raises(JWT::ExpiredSignature) { @api_token_authenticator.verify_token(token) }
  end

  test 'verifies EXP claim value and raises if token expired' do
    token = generate_token
    travel_to(Time.now + 5.minutes) do
      assert_raises(JWT::ExpiredSignature) { @api_token_authenticator.verify_token(token) }
    end
  end

  test 'verifies EXP claim value and raises if exp value too high' do
    token = generate_token(exp: (Time.now + 5.minutes + 2.seconds).to_i)
    assert_raises(JWT::InvalidPayload) { @api_token_authenticator.verify_token(token) }
  end

  test 'verifies JTI claim presence' do
    token = generate_token(jti: nil)
    assert_raises(JWT::InvalidJtiError) { @api_token_authenticator.verify_token(token) }
  end

  test 'verifies JTI claim format' do
    token = generate_token(jti: '!')
    assert_raises(JWT::InvalidJtiError) { @api_token_authenticator.verify_token(token) }
  end

  test 'can not verify the same token again on or after 5 minutes' do
    authenticator = ApiTokenAuthenticator.new(
      public_key_reader: ->(*) { @key_pair.public_key },
      return_handler: @return_handler
    )

    t1 = generate_token

    authenticator.verify_token(t1)

    travel_to(Time.now + 5.minutes) do
      assert_raises(JWT::ExpiredSignature) { authenticator.verify_token(t1) }
    end
  end

  class TokenDecoderFailure < ApiTokenAuthenticatorTest
    test 'raises decode error' do
      JWT.stub(:decode, ->(*) { raise JWT::DecodeError }) do
        assert_raises(JWT::DecodeError) do
          @api_token_authenticator.verify_token(generate_token)
        end
      end
    end
  end

  class PublicKeyReaderFailure < ApiTokenAuthenticatorTest
    test 'raises decode error' do
      authenticator = ApiTokenAuthenticator.new(
        public_key_reader: ->(*) { raise RuntimeError },
        return_handler: @return_handler
      )

      assert_raises(JWT::DecodeError) { authenticator.verify_token(generate_token) }
    end
  end

  class ReturnHandlerFailure < ApiTokenAuthenticatorTest
    test 'raises original error' do
      authenticator = ApiTokenAuthenticator.new(
        public_key_reader: @public_key_reader,
        return_handler: ->(*) { raise RuntimeError }
      )
      assert_raises(RuntimeError) { authenticator.verify_token(generate_token) }
    end
  end

  private

  def generate_token(sub: @sub, exp: 5.minutes.since(Time.now).to_i, jti: SecureRandom.uuid, **payload)
    JWT.encode(payload.merge(sub: sub, exp: exp, jti: jti).compact, @key_pair, 'RS256')
  end
end
