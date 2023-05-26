Rails.application.routes.draw do
  # TODO pridat namespace /admin/ a doriesit dopady
  resources :tenants do
    resources :groups
    resources :users
  end

  resources :group_memberships

  namespace :drafts, path: 'drafty' do
    resources :imports, path: 'importy', only: :create do
      get :upload_new, path: 'novy', on: :collection
    end
  end

  resources :drafts, path: 'drafty', only: [:index, :show, :destroy] do
    post :submit
    delete :destroy_all, path: 'zmazat', on: :collection if Rails.env.development?
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
      admin_ids = ENV.fetch('ADMIN_IDS','').split(',')

      admin_ids.include?(request.session['user_id'].to_s)
    end
  end

  constraints(GoodJobAdmin) do
    mount GoodJob::Engine => 'good_job'
  end
end
