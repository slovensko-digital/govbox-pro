module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      verified_user = User.find_by(id: cookies.encrypted['_govbox_pro_session']['user_id'])
      verified_user || reject_unauthorized_connection
    end
  end
end
