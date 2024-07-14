require "test_helper"

class UpvsMessageDraftsApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
    @box = boxes(:ssd_main)
    @before_request_messages_count = Message.count
  end

  test 'can upload valid message' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair)} ), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count
  end

  test 'can upload valid message with tags if they exist' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ],
      tags: ['Legal', 'Other']
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count

    assert Upvs::MessageDraft.last.tags.map(&:name).include?('Legal')
    assert Upvs::MessageDraft.last.tags.map(&:name).include?('Other')
  end

  test 'does not create message unless valid MessageDraft type' do
    message_params = {
      type: 'Vszp::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :bad_request

    json_response = JSON.parse(response.body)
    assert_equal "Disallowed message type: Vszp::MessageDraft", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless unique UUID in the box' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: @box.messages.first.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :conflict

    json_response = JSON.parse(response.body)
    assert_equal "Message with given UUID already exists", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless title present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "Title can't be blank", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless no box for given sender URI present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'NonExistentURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Invalid sender', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message if given sender URI for box in another tenant' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SolverMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Invalid sender', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless recipient in white list' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/87654321'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Recipient does not accept the form type', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless form type in white list' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Požiadanie o vyhotovenie kópie listiny uloženej v zbierke zákonom ustanovených listín obchodného registra',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: '00166073.MSSR_ORSR_Poziadanie_o_vyhotovenie_kopie_listiny_ulozenej_v_zbierke_listin.sk',
        posp_version: '1.53',
        message_type: 'ks_340702',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/87654321'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<ApplicationForDocumentCopy xmlns:e="http://schemas.gov.sk/form/00166073.MSSR_ORSR_Poziadanie_o_vyhotovenie_kopie_listiny_ulozenej_v_zbierke_listin.sk/1.53" xmlns="http://schemas.gov.sk/form/00166073.MSSR_ORSR_Poziadanie_o_vyhotovenie_kopie_listiny_ulozenej_v_zbierke_listin.sk/1.53">
          <MethodOfService>
            <Codelist>
              <CodelistCode>1000401</CodelistCode>
              <CodelistItem>
                <ItemCode>electronic</ItemCode>
                <ItemName Language="sk">v elektronickej podobe</ItemName>
              </CodelistItem>
            </Codelist>
          </MethodOfService>
          <DocumentsElectronicForm>
            <LegalPerson>
              <Codelist>
                <CodelistCode>MSSR-ORSR-LegalPerson</CodelistCode>
                <CodelistItem>
                  <ItemCode>53509285</ItemCode>
                  <ItemName Language="sk">J.J.Solar s. r. o. (IČO: 53509285, spisová značka: Sro/48243/T)</ItemName>
                  <Note Language="sk">eyJ2YWx1ZSI6IjUzNTA5Mjg1IiwidGV4dCI6IkouSi5Tb2xhciBzLiByLiBv
        LiAoScSMTzogNTM1MDkyODUsIHNwaXNvdsOhIHpuYcSNa2E6IFNyby80ODI0
        My9UKSIsInRpdGxlIjoiMTg4IEphbMWhb3bDqSIsImRlc2NyIjoie1wib2Rk
        aWVsXCI6MyxcInZsb3prYVwiOjQ4MjQzLFwic3VkXCI6N30iLCJuYW1lIjoi
        Si5KLlNvbGFyIHMuIHIuIG8uIChJxIxPOiA1MzUwOTI4NSwgc3Bpc292w6Eg
        em5hxI1rYTogU3JvLzQ4MjQzL1QpIiwiY29kZSI6IjUzNTA5Mjg1In0=
        </Note>
                </CodelistItem>
              </Codelist>
              <PersonData>
                <PhysicalAddress>
                  <AddressLine>188 Jalšové</AddressLine>
                </PhysicalAddress>
              </PersonData>
              <Document>
                <MakeCopy>true</MakeCopy>
                <Code>1</Code>
                <Name>Zakladateľská listina</Name>
              </Document>
              <Document>
                <MakeCopy>true</MakeCopy>
                <Code>3</Code>
                <Name>Vyhlásenie správcu vkladu</Name>
              </Document>
            </LegalPerson>
          </DocumentsElectronicForm>
          <Applicant>
            <PersonData>
              <ElectronicAddress>
                <InternetAddress>lucia.janikova@slovensko.digital</InternetAddress>
              </ElectronicAddress>
            </PersonData>
          </Applicant>
        </ApplicationForDocumentCopy>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Recipient does not accept the form type', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless message type in white list' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Požiadanie o vyhotovenie kópie listiny uloženej v zbierke zákonom ustanovených listín obchodného registra',
      uuid: SecureRandom.uuid,      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'ks_340702',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/87654321'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Recipient does not accept the form type', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless form is valid XML' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text & Poznamka</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }) , as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Form XSD validation failed', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless form valid against XSD' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
  <poznamka>Poznamocka</poznamka>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Form XSD validation failed', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless UUID present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)

    assert_equal "UUID can't be blank", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless Correlation ID present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "Correlation ID can't be blank", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless Recipient URI present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "No recipient URI", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless Posp ID present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "No posp ID", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless Posp version present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "No posp version", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless Message Type present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "No message type", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless Reference ID in valid format' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        reference_id: '12345',
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "Reference ID must be UUID", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless at least one message object present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        message_id: SecureRandom.uuid,
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: []
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Message contains no objects', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless form object present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Attachment.xml',
          is_signed: false,
          mimetype: 'application/xml',
          object_type: 'ATTACHMENT',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Message has to contain exactly one form object', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless exactly one form object present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        },
        {
          name: 'Attachment.xml',
          is_signed: false,
          mimetype: 'application/xml',
          object_type: 'FORM',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Message has to contain exactly one form object', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'can upload valid message with multiples objects' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        },
        {
          name: 'Attachment.xml',
          is_signed: false,
          mimetype: 'application/xml',
          object_type: 'ATTACHMENT',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        },
        {
          name: 'SignedAttachment.xml',
          is_signed: true,
          mimetype: 'application/xml',
          object_type: 'ATTACHMENT',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count

    assert Message.last.objects.last.tags.include?(tags(:ssd_signed_externally))
  end

  test 'can upload valid message with object tags if they exist' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>'),
          tags: ['Na podpis: Another user']
        }
      ],
      tags: ['Legal', 'Other']
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count
  end

  test 'can upload valid message with object SignatureRequestedFromTags if they exist' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>'),
          tags: ['Na podpis: Another user']
        }
      ],
      tags: ['Legal', 'Other']
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count

    assert Upvs::MessageDraft.last.objects.last.tags.map(&:name).include?('Na podpis: Another user')
  end

  test 'can upload valid message with object SignedByTags if they exist' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>'),
          tags: ['Podpísané: Another user']
        }
      ],
      tags: ['Legal', 'Other']
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count

    assert Upvs::MessageDraft.last.objects.last.tags.map(&:name).include?('Podpísané: Another user')
  end

  test 'does not create message unless object name present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        },
        {
          is_signed: false,
          mimetype: 'application/xml',
          object_type: 'ATTACHMENT',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "Objects is not valid, Name can't be blank", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end
  
  test 'does not create message unless object mimetype in white list' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        },
        {
          name: 'Attachment.txt',
          is_signed: false,
          mimetype: 'text/plain',
          object_type: 'ATTACHMENT',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert json_response['message'].start_with? 'Objects is not valid, MimeType of Attachment.txt object is disallowed, allowed mimetypes:'

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless tags with given names exist' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ],
      tags: ['Special']
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Tag with name Special does not exist', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless user signature tags with given names exist' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>'),
          tags: ['Podpisane']
        }
      ],
      tags: ['Legal', 'Other']
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Signature tag with name Podpisane does not exist', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end
end
