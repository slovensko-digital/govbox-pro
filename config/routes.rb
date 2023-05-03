Rails.application.routes.draw do
  # TODO add authentication
  namespace :admin do
    mount GoodJob::Engine => 'good_job'
  end

  namespace :drafts, path: 'drafty' do
    resources :imports, path: 'importy', only: :create do
      get :upload_new, path: 'novy', on: :collection
    end
  end

  resources :drafts, path: 'drafty', only: [:index, :show, :destroy] do
    post :submit
    delete :destroy_all, path: 'zmazat', on: :collection if Rails.env.development?
  end
end
