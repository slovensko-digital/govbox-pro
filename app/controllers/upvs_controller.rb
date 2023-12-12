class UpvsController < ActionController::API
  def login
    redirect_to '/auth/saml'
  end

  def callback
    response = request.env['omniauth.auth']['extra']['response_object']
    # TODO user is logged in
  end

  def logout
    if params[:SAMLRequest]
      #  TODO logout user
      redirect_to '/auth/saml/spslo'
    elsif params[:SAMLResponse]
      redirect_to "/auth/saml/slo?#{slo_response_params.to_query}"
    end
  end

  private

  def slo_request_params
    params.permit(:SAMLRequest, :SigAlg, :Signature)
  end

  def slo_response_params
    params.permit(:SAMLResponse, :SigAlg, :Signature)
  end

  # def obo_subject_id(assertion)
  #   Nokogiri::XML(assertion).at_xpath('//saml:Attribute[@Name="SubjectID"]/saml:AttributeValue').content
  # end
end
