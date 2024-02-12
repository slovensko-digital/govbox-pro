module Signer
  def self.sign(message_object, signing_option)
    cep_api = UpvsEnvironment.upvs_api(message_object.message.thread.box).cep
    cep_api_connection = ApiConnection.find(signing_option.settings["api_connection_id"])

    if message_object.mimetype == 'application/pdf'
      data = {
        objects: [
          {
            certificate_type: 'Subject',
            certificate_subject: signing_option.settings["certificate_subject"],
            signature_type: 'PAdES',
            class: 'http://schemas.gov.sk/attachment/pdf',
            mime_type: 'application/pdf',
            encoding: 'Base64',
            content: Base64.strict_encode64(message_object.content)
          }
        ]
      }
      signed_objects = cep_api.sign(data, cep_api_connection)
      signed_data = signed_objects&.first
    else
      data = {
        object_groups: [
          {
            id: SecureRandom.uuid,
            signing_certificate: {
              type: 'Subject',
              subject: signing_option.settings["certificate_subject"],
            },
            unsigned_objects: [
              {
                id: message_object_id(message_object),
                data: Base64.strict_encode64(message_object.content)
              }
            ],
          }
        ]
      }
      signed_objects = cep_api.sign_v2(data, cep_api_connection)
      signed_data = signed_objects&.first
    end

    signed_data
  end

  private

  def message_object_id(object)
    if object.form?
      "http://schemas.gov.sk/form/#{object.message.metadata["posp_id"]}/#{object.message.metadata["posp_version"]}/form.xsd"
    else
      case object.mimetype
      when 'text/plain'
        'http://schemas.gov.sk/attachment/txt'
      when 'image/png'
        'http://schemas.gov.sk/attachment/png'
      else
        raise "Unsupported MimeType"
      end
    end
  end
end
