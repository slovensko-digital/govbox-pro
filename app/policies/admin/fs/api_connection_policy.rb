class Admin::Fs::ApiConnectionPolicy < Admin::ApiConnectionPolicy
  def init?
    update?
  end

  def boxify?
    true
  end
end
