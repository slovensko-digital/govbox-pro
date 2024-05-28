# == Route Map
#

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
      resources :boxes, except: :destroy
      resources :tags
      resources :tag_groups
    end
    resources :audit_logs, only: :index do
      get :scroll, on: :collection
    end
  end

  resources :boxes, path: 'schranky', only: [] do
    post :sync
    post :sync_all, on: :collection
    get :select, on: :member
    get :select_all, on: :collection
    get :get_selector, on: :collection
    post :search, on: :collection
  end

  namespace "message_threads" do
    namespace "bulk" do
      resource :tags, only: [:update] do
        collection do
          post :edit
          post :prepare
          post :create_tag
        end
      end

      resource :message_drafts, only: [:update] do
        collection do
          post :submit
          put :destroy
        end
      end

      resource :authorize_deliveries, only: [:update]
      resource :archive, only: [:update]

      resource :signing, only: [:update] do
        post :new
        post :start
      end
    end
  end

  resources :message_threads do
    collection do
      get :scroll
      post :bulk_actions
      post :bulk_merge
    end
    get :rename, on: :member
    get :history, on: :member
    get :confirm_unarchive, on: :member
    patch :archive, on: :member
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

  resources :messages do
    member do
      post :reply
      post :authorize_delivery_notification
      get :export
    end

    resources :message_objects do
      member do
        get 'download'
        get 'download_pdf'
        get 'signing_data'
        get 'download_archived'
      end

      resources :nested_message_objects do
        get 'download'
        get 'download_pdf'
      end
    end
  end

  resources :filters do
    resources :filter_subscriptions
  end

  resources :message_drafts do
    member do
      post :confirm_unlock
      post :unlock
      post :submit
    end

    scope module: 'message_drafts' do
      resource :document_selections, only: [:new, :update] do
        collection do
          post :new
        end
      end

      resource :signature_requests, only: [:edit, :update] do
        collection do
          post :edit
          post :prepare
        end
      end

      resource :signing, only: [:new, :update] do
        collection do
          post :new
        end
      end
    end
  end

  resources :messages_tags

  resources :notifications do
    get :scroll, on: :collection
  end

  resource :settings

  resources :message_templates do
    get :recipient_selector
    get :recipients_list
    post :search_recipients_list
    post :recipient_selected
  end

  resources :message_drafts_imports, only: :create do
    get :upload_new, path: 'novy', on: :collection
  end

  namespace :upvs do
    get :allowed_recipient_services
  end

  resources :sessions do
    get :login, on: :collection
    get :no_account, on: :collection
    delete :destroy, on: :collection
  end

  namespace :api do
    namespace :site_admin do
      resources :tenants, only: [:create, :destroy] do
        resources :boxes, only: :create
        resources :api_connections, only: :create
      end

      namespace :stats do
        resources :tenants, only: [] do
          member do
            get :users_count
            get :messages_per_period
            get :messages_count
          end
        end
      end
    end

    resources :message_threads, only: [:show] do
      resources :tags, only: [:create] do
        delete :destroy, on: :collection
      end
    end
    resources :messages, only: [:show] do
      post :message_drafts, on: :collection
      get :sync, on: :collection
    end
  end

  if UpvsEnvironment.sso_support?
    namespace :upvs do
      get :login
      get :logout
    end

    scope 'auth/saml', as: :upvs, controller: :upvs do
      get :login
      get :logout

      post :callback
    end
  end

  get :auth, path: 'prihlasenie', to: 'sessions#login'
  get 'auth/google_oauth2/callback', to: 'sessions#create'
  get 'auth/google_oauth2/failure', to: 'sessions#failure'

  get "/service-worker.js" => "service_worker#service_worker"
  get "/manifest.json" => "service_worker#manifest"

  get "/health", to: "health_check#show"
  get "/health/jobs/failing", to: "health_check#failing_jobs"
  get "/health/jobs/stuck", to: "health_check#stuck_jobs"

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
