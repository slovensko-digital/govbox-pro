require 'test_helper'

# TODO write rails tests inspired by this RSpec code

class ApiEnvironmentTest < ActiveSupport::TestCase
#   it 'returns token authenticator' do
#     expect(subject.token_authenticator).to respond_to(:verify_token)
#   end

#   describe 'returned token authenticator' do
#     subject { described_class.token_authenticator }

#     let(:key_pair) { OpenSSL::PKey::RSA.new(512) }

#     it 'returns API box' do
#       box = create(:edesk_box, :active, :api_mode, api_token_public_key: key_pair.public_key)

#       expect(subject.verify_token(api_token(box, key_pair))).to eq([box, nil])
#     end

#     it 'fails on token verification for non-API box' do
#       box = create(:edesk_box, :active, :sync_mode, api_token_public_key: key_pair.public_key)

#       expect { subject.verify_token(api_token(box, key_pair)) }.to raise_error(JWT::DecodeError)
#     end

#     it 'fails on token verification for non-active box' do
#       box = create(:edesk_box, :ready, :api_mode, api_token_public_key: key_pair.public_key)

#       expect { subject.verify_token(api_token(box, key_pair)) }.to raise_error(JWT::DecodeError)
#     end

#     it 'fails on token verification for API box without public key' do
#       box = create(:edesk_box, :active, :api_mode, api_token_public_key: nil)

#       expect { subject.verify_token(api_token(box, key_pair)) }.to raise_error(JWT::DecodeError)
#     end
#   end
end
