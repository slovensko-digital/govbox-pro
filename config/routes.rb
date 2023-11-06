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
      patch :rerender
    end
    resources :automation_actions, param: :index do
      post '/', to: 'automation_actions#edit_form', on: :member
      patch :rerender
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

  resources :boxes, path: 'schranky', only: %i[index show] do
    post :sync
    get :select, on: :member
    get :select_all, on: :collection
    get :get_selector, on: :collection
    post :search, on: :collection
  end

  resources :message_threads do
    collection do
      get :scroll
      post :bulk_actions
      post :bulk_merge
    end
    get :rename, on: :member
    resources :messages
    resources :message_thread_notes
    scope module: 'message_threads' do
      resource :tags, only: [:edit, :update] do
        post :prepare, on: :member
        post :create_tag, on: :member
      end
    end
  end

  resources :message_threads_tags, only: :destroy

  namespace "message_threads_bulk" do
    namespace "tags" do
      post :edit, to: "edit"
      post :prepare, to: "prepare"
      post :create_tag, to: "create_tag"
      post :update, to: "update"
    end
  end

  resources :messages do
    member do
      post 'authorize_delivery_notification'
    end

    resources :message_objects do
      member do
        get 'download'
        get 'signing_data'
      end

      resources :nested_message_objects do
        get 'download'
      end
    end
  end

  resources :filters

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
