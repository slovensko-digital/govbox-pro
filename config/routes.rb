require 'que/web'

Rails.application.routes.draw do
  # TODO add authentication
  namespace :admin do
    namespace :que do
      mount Que::Web, at: '/'
    end
  end

  resources :submissions, path: 'podania', only: [:index, :new, :create, :show] do
    post :submit

    collection do
      get 'novy-balik', to: 'submissions#new'
    end
  end
end
