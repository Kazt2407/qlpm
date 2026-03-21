Rails.application.routes.draw do
  root "dashboard#index"

  resources :devices do
    member do
      patch :update_status
    end
  end

  resources :borrows do
    member do
      patch :confirm_return
      post  :send_reminder
    end
  end

  get  "reports",          to: "reports#index",   as: :reports
  get  "reports/export",   to: "reports#export",  as: :export_reports
end
