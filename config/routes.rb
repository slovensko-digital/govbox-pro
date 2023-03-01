require 'que/web'

Rails.application.routes.draw do
  resources :submissions, path: 'podania', only: [:index, :new, :create, :show] do
    post :submit

    collection do
      get 'novy-balik', to: 'submissions#new'
    end
  end

  namespace :admin do
    namespace :que do
      mount Que::Web, at: '/'
    end
  end
end
