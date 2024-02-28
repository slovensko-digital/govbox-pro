module TurboReload
  def set_reload
    @turbo_reload = session[:turbo_reload] == "1"

    session[:turbo_reload] = nil
  end

  def request_turbo_reload
    session[:turbo_reload] = "1"
  end
end
