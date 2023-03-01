require 'que/web'

Rails.application.routes.draw do
  # TODO add authentication
  namespace :admin do
    namespace :que do
      mount Que::Web, at: '/'
    end
  end
end
