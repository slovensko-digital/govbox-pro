Rails.application.routes.draw do
  resource :dashboard

  # TODO pridat namespace /admin/ a doriesit dopady
  namespace :admin do
    resources :tenants do
      resources :groups
      resources :users
      resources :boxes
    end

    resources :group_memberships
  end

  namespace :drafts, path: "drafty" do
    resources :imports, path: "importy", only: :create do
      get :upload_new, path: "novy", on: :collection
    end
  end

  resources :drafts, path: "drafty", only: %i[index show destroy] do
    post :submit
    post :submit_all, on: :collection
    delete :destroy_all, path: "zmazat", on: :collection

    # TODO uncomment later and remove ^ 2 endpoints
    post :submit_all, on: :collection if Rails.env.development?
    if Rails.env.development?
      delete :destroy_all, path: "zmazat", on: :collection
    end
  end

  resources :sessions do
    get :login, on: :collection
    delete :destroy, on: :collection
  end

  get :auth, path: "prihlasenie", to: "sessions#login"
  get "auth/google_oauth2/callback", to: "sessions#create"
  get "auth/google_oauth2/failure", to: "sessions#failure"

  root "dashboard#show"

  class GoodJobAdmin
    def self.matches?(request)
      admin_ids = ENV.fetch("ADMIN_IDS", "").split(",")

      admin_ids.include?(request.session["user_id"].to_s)
    end
  end

  constraints(GoodJobAdmin) { mount GoodJob::Engine => "good_job" }
end
