Rails.application.routes.draw do
    resources :submission_packages, path: 'hromadne-podania', only: :create do
    get :upload_new, path: 'nove', on: :collection
    post :submit, path: 'podat'
  end

  resources :submissions, path: 'podania', only: [:index, :show, :destroy] do
    post :submit, path: 'podat'
    delete :destroy_all, path: 'zmazat', on: :collection
  end

  resources :sessions do
    get :login, on: :collection
    delete :destroy, on: :collection
  end

  get :auth, path: "prihlasenie", to: 'sessions#login'
  get "auth/google_oauth2/callback", to: "sessions#create"
  get "auth/google_oauth2/failure", to: "sessions#failure"

  root "sessions#login"

  class GoodJobAdmin
    def self.matches?(request)
      cookies = ActionDispatch::Cookies::CookieJar.build(request, request.cookies)
      admin_ips = ENV.fetch('ADMIN_IDS','').split(',')

      admin_ips.include?(cookies.encrypted['user_id'].to_s)
    end
  end

  constraints(GoodJobAdmin) do
    mount GoodJob::Engine => 'good_job'
  end
end
