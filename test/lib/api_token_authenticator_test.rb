require 'test_helper'

# TODO write rails tests inspired by this RSpec code

class ApiTokenAuthenticatorTest < ActiveSupport::TestCase
  # REPLAY_EPSILON = 15.minutes
  # REPLAY_DELTA = described_class::MAX_EXP_IN - REPLAY_EPSILON

  # let(:sub) { 'SPL_Irvin_50158635_11012019' }
  # let(:key_pair) { OpenSSL::PKey::RSA.new(512) }

  # let(:identifier_store) { ApiEnvironment.token_identifier_store }
  # let(:public_key_reader) { -> (s) { s == sub ? key_pair.public_key : raise }}
  # let(:return_handler) { -> (s) { s }}

  # subject { described_class.new(identifier_store: identifier_store, public_key_reader: public_key_reader, return_handler: return_handler) }

  # before(:example) { identifier_store.clear }

  # before(:example) { travel_to '2018-11-28T20:26:16Z' }

  # describe '#verify_token' do
  #   def generate_token(sub: 'SPL_Irvin_50158635_11012019', exp: 1543443976, jti: SecureRandom.uuid, **payload)
  #     JWT.encode(payload.merge(sub: sub, exp: exp, jti: jti).compact, key_pair, 'RS256')
  #   end

  #   it 'returns SUB, OBO claim values' do
  #     expect(subject.verify_token(generate_token)).to eq([sub, nil])
  #   end

  #   it 'verifies format' do
  #     expect { subject.verify_token(nil) }.to raise_error(JWT::DecodeError)
  #     expect { subject.verify_token('NON-JWT') }.to raise_error(JWT::DecodeError)
  #   end

  #   it 'verifies algorithm' do
  #     token = JWT.encode({ sub: sub }, 'KEY', 'HS256')

  #     expect { subject.verify_token(token) }.to raise_error(JWT::IncorrectAlgorithm)
  #   end

  #   it 'verifies signature' do
  #     token = JWT.encode({ sub: sub }, OpenSSL::PKey::RSA.new(512), 'RS256')

  #     expect { subject.verify_token(token) }.to raise_error(JWT::VerificationError)
  #   end

  #   it 'verifies SUB claim presence' do
  #     token = generate_token(sub: nil)

  #     expect { subject.verify_token(token) }.to raise_error(JWT::InvalidSubError)
  #   end

  #   it 'verifies SUB claim value' do
  #     token = generate_token(sub: 'unknown-subject')

  #     expect { subject.verify_token(token) }.to raise_error(JWT::InvalidSubError)
  #   end

  #   it 'verifies EXP claim presence' do
  #     token = generate_token(exp: nil)

  #     expect { subject.verify_token(token) }.to raise_error(JWT::ExpiredSignature)
  #   end

  #   it 'verifies EXP claim value' do
  #     token = generate_token

  #     travel_to Time.now + 120.minutes

  #     expect { subject.verify_token(token) }.to raise_error(JWT::ExpiredSignature)
  #   end

  #   it 'verifies JTI claim presence' do
  #     token = generate_token(jti: nil)

  #     expect { subject.verify_token(token) }.to raise_error(JWT::InvalidJtiError)
  #   end

  #   it 'verifies JTI claim format' do
  #     token = generate_token(jti: '!')

  #     expect { subject.verify_token(token) }.to raise_error(JWT::InvalidJtiError)
  #   end

  #   it 'verifies JTI claim value' do
  #     token = generate_token

  #     subject.verify_token(token)

  #     expect { subject.verify_token(token) }.to raise_error(JWT::InvalidJtiError)
  #   end

  #   context 'token replay attacks' do
  #     let(:public_key_reader) { -> (*) { key_pair.public_key }}

  #     it 'can not verify the same token twice in the first 120 minutes' do
  #       t1 = generate_token

  #       subject.verify_token(t1)

  #       travel_to Time.now + 120.minutes - 0.1.seconds

  #       expect { subject.verify_token(t1) }.to raise_error(JWT::InvalidJtiError)
  #     end

  #     it 'can not verify the same token again on or after 120 minutes' do
  #       t1 = generate_token

  #       subject.verify_token(t1)

  #       travel_to Time.now + 120.minutes

  #       expect { subject.verify_token(t1) }.to raise_error(JWT::ExpiredSignature)
  #     end

  #     it 'can not verify another token with the same JTI and SUB claims in the first 120 minutes' do
  #       jti = SecureRandom.uuid

  #       t1 = generate_token(sub: 0, exp: (Time.now + 120.minutes).to_i, jti: jti)

  #       subject.verify_token(t1)

  #       travel_to Time.now + REPLAY_DELTA

  #       t2 = generate_token(sub: 0, exp: (Time.now + 120.minutes).to_i, jti: jti)

  #       travel_to Time.now + REPLAY_EPSILON - 0.1.seconds

  #       expect(identifier_store).to receive(:write).with(any_args).and_call_original

  #       expect { subject.verify_token(t2) }.to raise_error(JWT::InvalidJtiError)
  #     end

  #     it 'can verify another token with the same JTI and SUB claims again on or after 120 minutes' do
  #       jti = SecureRandom.uuid

  #       t1 = generate_token(sub: 0, exp: (Time.now + 120.minutes).to_i, jti: jti)

  #       subject.verify_token(t1)

  #       travel_to Time.now + REPLAY_DELTA

  #       t2 = generate_token(sub: 0, exp: (Time.now + 120.minutes).to_i, jti: jti)

  #       travel_to Time.now + REPLAY_EPSILON

  #       expect(identifier_store).to receive(:write).with(any_args).and_return(true)

  #       expect { subject.verify_token(t2) }.not_to raise_error
  #     end

  #     it 'can verify another token with the same JTI claim but different SUB claim in the first 120 minutes' do
  #       jti = SecureRandom.uuid

  #       t1 = generate_token(sub: 0, exp: (Time.now + 120.minutes).to_i, jti: jti)

  #       subject.verify_token(t1)

  #       travel_to Time.now + REPLAY_DELTA

  #       t2 = generate_token(sub: 1, exp: (Time.now + 120.minutes).to_i, jti: jti)

  #       travel_to Time.now + REPLAY_EPSILON - 0.1.seconds

  #       expect(identifier_store).to receive(:write).with(any_args).and_call_original

  #       expect { subject.verify_token(t2) }.not_to raise_error
  #     end

  #     it 'can verify another token with the same JTI claim but different SUB claim again on or after 120 minutes' do
  #       jti = SecureRandom.uuid

  #       t1 = generate_token(sub: 0, exp: (Time.now + 120.minutes).to_i, jti: jti)

  #       subject.verify_token(t1)

  #       travel_to Time.now + REPLAY_DELTA

  #       t2 = generate_token(sub: 1, exp: (Time.now + 120.minutes).to_i, jti: jti)

  #       travel_to Time.now + REPLAY_EPSILON

  #       expect(identifier_store).to receive(:write).with(any_args).and_return(true)

  #       expect { subject.verify_token(t2) }.not_to raise_error
  #     end
  #   end

  #   context 'token decoder failure' do
  #     before(:example) { expect(JWT).to receive(:decode).with(any_args).and_raise(JWT::DecodeError) }

  #     it 'raises decode error' do
  #       expect { subject.verify_token(generate_token) }.to raise_error(JWT::DecodeError)
  #     end
  #   end

  #   context 'identifier store failure' do
  #     let(:identifier_store) { redis_cache_store_without_connection }

  #     it 'raises original error' do
  #       expect { subject.verify_token(generate_token) }.to raise_error(ApiEnvironment::RedisConnectionError)
  #     end
  #   end

  #   context 'public key reader failure' do
  #     let(:public_key_reader) { -> (*) { raise RuntimeError }}

  #     it 'raises decode error' do
  #       expect { subject.verify_token(generate_token) }.to raise_error(JWT::DecodeError)
  #     end
  #   end

  #   context 'return handler failure' do
  #     let(:return_handler) { -> (*) { raise RuntimeError }}

  #     it 'raises original error' do
  #       expect { subject.verify_token(generate_token) }.to raise_error(RuntimeError)
  #     end
  #   end
  # end
end
