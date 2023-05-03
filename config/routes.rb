Rails.application.routes.draw do
  # TODO add authentication
  namespace :admin do
    mount GoodJob::Engine => 'good_job'
  end

  resources :submission_packages, path: 'hromadne-podania', only: :create do
    get :upload_new, path: 'nove', on: :collection
  end

  resources :submissions, path: 'podania', only: [:index, :show, :destroy] do
    post :submit
    delete :destroy_all, path: 'zmazat', on: :collection if Rails.env.development?
  end
end
