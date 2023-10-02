Rails.application.routes.draw do
  namespace :settings do
    resources :automation_rules
    resource :automation_rule do
      post :header_step
      patch :header_step
      post :conditions_step
      patch :conditions_step
      post :actions_step
      patch :actions_step
    end
    resources :automation_conditions, param: :index do
      post '/', to: 'automation_conditions#edit_form', on: :member
    end
    resources :automation_actions, param: :index do
      post '/', to: 'automation_actions#edit_form', on: :member
    end
    resources :tags
    resource :profile
  end

  namespace :admin do
    resources :tenants do
      resources :groups do
        get :edit_members, on: :member
        get :show_members, on: :member
        get :edit_permissions, on: :member
        post :search_non_members, on: :member
        post :search_non_tags, on: :member
        resources :group_memberships do
        end
      end
      resources :users
      resources :boxes
      resources :tags
      resources :tag_groups
    end
  end

  resources :boxes, path: 'schranky', only: [:index, :show] do
    post :sync
    get :select, on: :member
    get :select_all, on: :collection
    get :get_selector, on: :collection
    post :search, on: :collection
  end

  resources :message_threads do
    collection do
      post :merge
      get :scroll
    end
    get :available_tags, on: :member
    post :available_tags, on: :member
    resources :messages
  end
  resources :message_threads_tags
  resources :tags

  resources :messages do
    member do
      post 'authorize_delivery_notification'
    end

    resources :message_objects do
      member do
        get 'download'
        get 'signing_data'
      end
    end
  end

  resources :message_drafts do
    member do
      post 'submit'
    end

    post 'submit_all', on: :collection
  end

  resources :messages_tags

  resource :settings

  resources :message_drafts_imports, only: :create do
    get :upload_new, path: 'novy', on: :collection
  end

  resources :sessions do
    get :login, on: :collection
    delete :destroy, on: :collection
  end

  get :auth, path: 'prihlasenie', to: 'sessions#login'
  get 'auth/google_oauth2/callback', to: 'sessions#create'
  get 'auth/google_oauth2/failure', to: 'sessions#failure'

  root 'message_threads#index'

  class GoodJobAdmin
    def self.matches?(request)
      User.find(request.session['user_id'])&.site_admin?
    end
  end

  constraints(GoodJobAdmin) do
    mount GoodJob::Engine => 'good_job'
  end
end
