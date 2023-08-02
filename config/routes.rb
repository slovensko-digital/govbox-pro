Rails.application.routes.draw do
  namespace :settings do
    resources :automation_rules do
      resources :automation_conditions
      resources :automation_actions
    end
    resources :tags
    resource :profile
  end

  namespace :admin do
    resources :tenants do
      resources :groups
      resources :users
      resources :boxes
      resources :tags
    end

    resources :group_memberships
    resources :tag_users
  end

  resources :boxes, path: 'schranky', only: [:index, :show] do
    post :sync
  end

  resources :tags do
    resources :message_threads do
    end    
  end

  resources :message_threads do
    collection do
      get 'merge'
    end
    resources :messages
  end
  resources :message_threads_tags

  resources :messages do
    member do
      post 'authorize_delivery_notification'
    end

    resources :message_objects do
      member do
        get 'download'
      end
    end
  end

  resources :message_drafts do
    member do
      post 'submit'
    end
  end

  resources :messages_tags

  resource :settings

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
