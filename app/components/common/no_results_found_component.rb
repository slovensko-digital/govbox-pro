module Common
  class NoResultsFoundComponent < ViewComponent::Base
    def initialize(message_header, message_body)
      @message_header = message_header || "Nenašli sme žiadne výsledky"
      @message_body = message_body || "Skúste zmeniť filter alebo vyhľadávané slová"
    end
  end
end
