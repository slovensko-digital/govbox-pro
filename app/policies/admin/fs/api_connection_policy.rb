class Admin::Fs::ApiConnectionPolicy < Admin::ApiConnectionPolicy
  def boxify?
    true
  end
end
