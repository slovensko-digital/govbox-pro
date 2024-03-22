require "test_helper"

class ThreadsApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
    @before_request_messages_count = Message.count
  end


  test 'can upload valid message' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count
  end

  test 'can upload valid message with tags if they exist' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count

    assert Upvs::MessageDraft.last.tags.map(&:name).include?('Legal')
    assert Upvs::MessageDraft.last.tags.map(&:name).include?('Other')
  end

  test 'marks message invalid unless title present' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "Title can't be blank", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless no box for given sender URI present' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'NonExistentURI',
      recipient_uri: 'ico://sk/12345678',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Invalid Sender Uri', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid if given sender URI for box in another tenant' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SolverMainURI',
      recipient_uri: 'ico://sk/12345678',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Invalid Sender Uri', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless recipient in white list' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/87654321',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Recipient does not accept the form type', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless form type in white list' do
    message_params = {
      posp_id: '00166073.MSSR_ORSR_Poziadanie_o_vyhotovenie_kopie_listiny_ulozenej_v_zbierke_listin.sk',
      posp_version: '1.53',
      message_type: 'ks_340702',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/87654321',
      title: 'Požiadanie o vyhotovenie kópie listiny uloženej v zbierke zákonom ustanovených listín obchodného registra',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Recipient does not accept the form type', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless message type in white list' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'ks_340702',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/87654321',
      title: 'Požiadanie o vyhotovenie kópie listiny uloženej v zbierke zákonom ustanovených listín obchodného registra',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Recipient does not accept the form type', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless form is valid XML' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Form XSD validation failed', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless form valid against XSD' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Form XSD validation failed', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless Message ID present' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)

    assert_equal "Message ID can't be blank", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless Correlation ID present' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "Correlation ID can't be blank", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless Recipient URI present' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "No recipient URI", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless Posp ID present' do
    message_params = {
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "No posp ID", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless Posp version present' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "No posp version", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless Message Type present' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "No message type", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless Reference ID in valid format' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      reference_id: '12345',
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "Reference ID must be UUID", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless at least one message object present' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
      objects: []
    }

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Message contains no objects', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless form object present' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Message has to contain exactly one form object', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless exactly one form object present' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Message has to contain exactly one form object', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless object name present' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "Objects is not valid, Name can't be blank", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end
  
  test 'marks message invalid unless object mimetype in white list' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Objects is not valid, MimeType of Attachment.txt object is disallowed, allowed mimetypes: application/x-eform-xml, application/xml, application/msword, application/pdf, application/vnd.etsi.asic-e+zip, application/vnd.etsi.asic-s+zip, application/vnd.openxmlformats-officedocument.wordprocessingml.document, application/x-xades_zep, application/x-zip-compressed, image/jpg, image/jpeg, image/png, image/tiff', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'marks message invalid unless tags with given names exist' do
    message_params = {
      posp_id: 'App.GeneralAgenda',
      posp_version: '1.9',
      message_type: 'App.GeneralAgenda',
      message_id: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      sender_uri: 'SSDMainURI',
      recipient_uri: 'ico://sk/12345678',
      title: 'Všeobecná agenda',
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

    post '/api/upvs/messages', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal 'Tag with name Special does not exist', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end
end

