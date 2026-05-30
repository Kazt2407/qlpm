Rails.application.routes.draw do
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  root "dashboard#index"

  resources :assets
  resources :rooms
  resources :work_orders
  resource :schedule, only: :show
  resource :borrow_import, only: %i[new create] do
    post :commit
  end
  resources :borrows do
    member do
      patch :confirm_return
      post  :send_reminder
      patch :approve
      patch :reject
      patch :cancel
    end
  end
  resources :users, except: %i[show] do
    member do
      patch :toggle_active
      patch :reset_password
    end
  end

  namespace :veyon do
    resources :hosts do
      collection do
        get :rooms
        post :execute_room_feature
      end
      member do
        get :framebuffer
        post :execute_feature
        post :refresh_status
      end
    end
  end

  get  "reports",          to: "reports#index",   as: :reports
  get  "reports/export",   to: "reports#export",  as: :export_reports
end
