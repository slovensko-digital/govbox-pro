require 'que/web'

Rails.application.routes.draw do
  # TODO add authentication
  namespace :admin do
    namespace :que do
      mount Que::Web, at: '/'
    end
  end

  resources :submission_packages, path: 'hromadne-podania', only: [:index, :create, :show] do
    get :upload_new, path: 'nove', on: :collection
    post :submit
  end
end
