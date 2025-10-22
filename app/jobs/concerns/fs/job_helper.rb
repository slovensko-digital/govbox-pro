module Fs::JobHelper
  extend ActiveSupport::Concern

  def find_api_connection_for_outbox_message(outbox_message)
    return outbox_message.box.api_connection if outbox_message.box.api_connections.count == 1

    signed_by = outbox_message.form_object.tags.where(type: "SignedByTag")&.first&.owner
    signers_api_connection = outbox_message.box.api_connections.find_by(owner: signed_by)
    signers_api_connection if signed_by && signers_api_connection
  end
end
