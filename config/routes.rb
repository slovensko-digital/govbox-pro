Rails.application.routes.draw do
  resource :dashboard

  namespace :admin do
    resources :tenants do
      resources :groups
      resources :users
      resources :boxes
    end

    resources :group_memberships
  end

  resources :boxes, path: 'schranky', only: [:index, :show] do
    post :sync
  end

  resources :folders do
    resources :message_threads
  end

  resources :message_threads do
    resources :messages
  end

  resources :messages do
    resources :message_objects do
      member do
        get 'download'
      end
    end
  end

  namespace :drafts, path: 'drafty' do
    resources :imports, path: 'importy', only: :create do
      get :upload_new, path: 'novy', on: :collection
    end
  end

  resources :drafts, path: 'drafty', only: %i[index show destroy] do
    post :submit
    post :submit_all, on: :collection
  end

  resources :sessions do
    get :login, on: :collection
    delete :destroy, on: :collection
  end

  get :auth, path: 'prihlasenie', to: 'sessions#login'
  get 'auth/google_oauth2/callback', to: 'sessions#create'
  get 'auth/google_oauth2/failure', to: 'sessions#failure'

  root 'dashboard#show'

  class GoodJobAdmin
    def self.matches?(request)
      admin_ids = ENV.fetch('ADMIN_IDS', '').split(',')

      admin_ids.include?(request.session['user_id'].to_s)
    end
  end

  constraints(GoodJobAdmin) do
    mount GoodJob::Engine => 'good_job'
  end
end
