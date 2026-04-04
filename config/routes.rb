Rails.application.routes.draw do
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  root "dashboard#index"

  resources :assets
  resources :borrows do
    member do
      patch :confirm_return
      post  :send_reminder
    end
  end
  resources :users, only: %i[index]

  get  "reports",          to: "reports#index",   as: :reports
  get  "reports/export",   to: "reports#export",  as: :export_reports
end
