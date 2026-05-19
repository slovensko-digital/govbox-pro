require "test_helper"

class FsMessageDraftsApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:accountants)
    @box = boxes(:fs_accountants2)
    @before_request_messages_count = Message.count
  end

  test 'can upload valid message' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]


    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair)} ), as: :json

      assert_response :created
      assert_not_equal Message.count, @before_request_messages_count
      assert @box, Message.last.box
    end
  end

  test 'can upload valid message with attachment' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'VP_DANv24_fo Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'vp_danv24_fo.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/vp_danv24_fo.xml").read)
        },
        {
          name: 'priloha.pdf',
          is_signed: false,
          to_be_signed: false,
          mimetype: 'application/pdf',
          object_type: 'ATTACHMENT',
          content: Base64.encode64(file_fixture("lorem_ipsum.pdf").read)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "3078_781"
    },
    [file_fixture("fs/vp_danv24_fo.xml").read]


    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair)} ), as: :json

      assert_response :created
      assert_not_equal Message.count, @before_request_messages_count
      assert @box, Message.last.box
    end
  end

  test 'sets metadata' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599",
      "period" => {
        "pretty" => "082025"
      }
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair)} ), as: :json

      assert_response :created
      assert_equal "082025", Message.last.metadata['period']
      assert_equal "SVDPHv20", Message.last.metadata['fs_form_slug']
      assert_equal "Riadny", Message.last.metadata['fs_form_subtype_name']
    end
  end

  test 'SignatureRestedTag is assigned from SignerGroup if object marked to_be_signed' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair)} ), as: :json

      assert_response :created
      assert @box.messages.last.objects.first.tags.include?(@tenant.signer_group.signature_requested_from_tag)
      assert @box.messages.last.thread.tags.include?(@tenant.signature_requested_tag!)
    end
  end

  test 'can upload valid message with tags if they exist' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read)
        }
      ],
      tags: ['Tag 1', 'Tag 2']
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :created
      assert_not_equal Message.count, @before_request_messages_count

      assert @box.messages.last.tags.map(&:name).include?('Tag 1')
      assert @box.messages.last.tags.map(&:name).include?('Tag 2')
    end
  end

  test 'does not create message unless tags with given names exist' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read)
        }
      ],
      tags: ['Special']
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal 'Tag with name Special does not exist', json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message if SignatureRequestedTag on an attachment' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'VP_DANv24_fo Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'vp_danv24_fo.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/vp_danv24_fo.xml").read)
        },
        {
          name: 'priloha.pdf',
          is_signed: false,
          to_be_signed: false,
          mimetype: 'application/pdf',
          object_type: 'ATTACHMENT',
          content: Base64.encode64(file_fixture("lorem_ipsum.pdf").read),
          tags: ['Na podpis: Basic user 2']
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "3078_781"
    },
                  [file_fixture("fs/vp_danv24_fo.xml").read]


    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal 'Cannot assign SignatureRequestedFromTag to an object that is not signable', json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message if signature requested on an attachment' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'VP_DANv24_fo Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'vp_danv24_fo.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/vp_danv24_fo.xml").read)
        },
        {
          name: 'priloha.pdf',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/pdf',
          object_type: 'ATTACHMENT',
          content: Base64.encode64(file_fixture("lorem_ipsum.pdf").read)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "3078_781"
    },
                  [file_fixture("fs/vp_danv24_fo.xml").read]


    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal 'Cannot mark object as to_be_signed if it is not signable', json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message unless unique UUID in the box' do
    @box = boxes(:fs_accountants)

    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: @box.messages.first.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334455",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :conflict

      json_response = JSON.parse(response.body)
      assert_equal "Message with given UUID already exists", json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message unless title present' do
    message_params = {
      type: 'Fs::MessageDraft',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal "Title can't be blank", json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message unless box for given DIC present' do
    form_content = file_fixture("fs/svdph_valid.xml").read
    form_content.gsub!('1122334456', '001122334455')

    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(form_content)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "001122334455",
      "form_identifier" => "708_599"
    },
    [form_content]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal 'Invalid sender', json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message unless neither DIC, FS form identified' do
    form_content = file_fixture("fs/random_xml.xml").read

    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(form_content)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, nil,
    [form_content]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal 'Invalid sender', json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message unless neither FS form identified' do
    form_content = file_fixture("fs/svdph_invalid.xml").read

    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(form_content)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
    },
    [form_content]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal 'Unknown form', json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message if given sender URI for box in another tenant' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "9988776655",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal 'Invalid sender', json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message unless form is valid XML' do
    form_content = file_fixture("fs/svdph_valid.xml").read + '<ExtraTag>A & B</ExtraTag>'

    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(form_content)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [form_content]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }) , as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal 'Form XSD validation failed', json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message unless UUID present' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)

      assert_equal "UUID can't be blank", json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message unless Correlation ID present' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal "Correlation ID can't be blank", json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message unless form object present' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      }
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal 'Message has to contain exactly one form object', json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message if more than one form object present' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read)
        },
        {
          name: 'attachment.xml',
          is_signed: false,
          mimetype: 'application/xml',
          object_type: 'FORM',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal 'Message has to contain exactly one form object', json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'can upload valid message with object SignatureRequestedFromTags if they exist' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read),
          tags: ['Na podpis: Basic user 2']
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :created
      assert_not_equal Message.count, @before_request_messages_count

      assert @box.messages.last.objects.last.tags.map(&:name).include?('Na podpis: Basic user 2')
    end
  end

  test 'can upload valid message with object SignedByTags if they exist' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read),
          tags: ['Podpísané: Basic user 2']
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :created
      assert_not_equal Message.count, @before_request_messages_count

      assert @box.messages.last.objects.last.tags.map(&:name).include?('Podpísané: Basic user 2')
    end
  end

  test 'does not create message unless object name present' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read)
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal "Objects is not valid, Name can't be blank", json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end

  test 'does not create message unless user signature tags with given names exist' do
    message_params = {
      type: 'Fs::MessageDraft',
      title: 'SVDPH Podanie',
      uuid: SecureRandom.uuid,
      metadata: {
        correlation_id: SecureRandom.uuid
      },
      objects: [
        {
          name: 'test_svdph.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'text/xml',
          object_type: 'FORM',
          content: Base64.encode64(file_fixture("fs/svdph_valid.xml").read),
          tags: ['Podpísané Ferko']
        }
      ]
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :parse_form, {
      "subject" => "1122334456",
      "form_identifier" => "708_599"
    },
    [file_fixture("fs/svdph_valid.xml").read]

    FsEnvironment.fs_client.stub :api, fs_api do
      post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

      assert_response :unprocessable_content

      json_response = JSON.parse(response.body)
      assert_equal 'Signature tag with name Podpísané Ferko does not exist', json_response['message']

      assert_equal Message.count, @before_request_messages_count
    end
  end
end
