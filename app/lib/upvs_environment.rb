module UpvsEnvironment

  def self.sso_settings
    # TODO remove the next line to support live UPVS specs, need to figure out how to bring /security into CI first
    return {} if Rails.env.test?

    return @sso_settings if @sso_settings

    idp_metadata = OneLogin::RubySaml::IdpMetadataParser.new.parse_to_hash(File.read(sso_metadata_file(:idp)))
    sp_metadata = Hash.from_xml(File.read(sso_metadata_file(:sp))).fetch('EntityDescriptor')
    # TODO is there a reason for SP sign cert to be in JKS file? (move it to PEM file under security/sso); remove lib/keystore.rb
    sp_keystore = KeyStore.new(sso_keystore_file, generate_pass(:ks))

    @sso_settings ||= idp_metadata.merge(
      request_path: '/auth/saml',
      callback_path: '/auth/saml/callback',

      issuer: sp_metadata['entityID'],
      assertion_consumer_service_url: sp_metadata['SPSSODescriptor']['AssertionConsumerService'].first['Location'],
      single_logout_service_url: sp_metadata['SPSSODescriptor']['SingleLogoutService'].first['Location'],
      idp_sso_target_url: idp_metadata[:idp_sso_service_url],
      idp_slo_target_url: idp_metadata[:idp_slo_service_url],
      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
      protocol_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
      sp_name_qualifier: sp_metadata['entityID'],
      idp_name_qualifier: idp_metadata[:idp_entity_id],

      # TODO this gets called on IDP initiated logout, we need to invalidate SAML assertion here! removing assertion actually invalidates OBO token which is the desired effect here (cover it in specs)
      idp_slo_session_destroy: proc { |env, session| },

      certificate: sp_keystore.certificate_in_base64,
      private_key: sp_keystore.private_key_in_base64(generate_pass(:pk)),

      security: {
        authn_requests_signed: true,
        logout_requests_signed: true,
        logout_responses_signed: true,
        want_assertions_signed: true,
        want_assertions_encrypted: true,
        want_name_id: true,
        metadata_signed: true,
        embed_sign: true,

        digest_method: XMLSecurity::Document::SHA512,
        signature_method: XMLSecurity::Document::RSA_SHA512,
      },

      double_quote_xml_attribute_values: true,
      force_authn: false,
      passive: false
    )
  end

  def self.sso_support?
    @sso_support ||= ENV.key?('UPVS_SSO')
  end

  private

  def self.generate_pass(type)
    return 'password' unless Upvs.env.prod?
    salt = ENV.fetch("UPVS_#{type.to_s.upcase}_SALT")
    raise "Short #{type.to_s.upcase} salt" if Upvs.env.prod? && salt.size < 40
    Digest::SHA1.hexdigest("#{salt}:upvs")
  end

  def self.sso_keystore_file
    Rails.root.join('security', "upvs_#{Upvs.env}.sp.keystore").to_s
  end

  def self.sso_sp_metadata_file(type)
    Rails.root.join('security', "upvs_#{Upvs.env}.#{type.to_s}.metadata.xml").to_s
  end
end
