require 'que/web'

Rails.application.routes.draw do
  # TODO add authentication
  namespace :admin do
    namespace :que do
      mount Que::Web, at: '/'
    end
  end

  resources :submission_packages, path: 'hromadne-podania', only: :create do
    get :upload_new, path: 'nove', on: :collection
    post :submit, path: 'podat'
  end

  resources :submissions, path: 'podania', only: [:index, :show, :destroy] do
    post :submit, path: 'podat'
  end
end
