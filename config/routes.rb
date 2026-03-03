Rails.application.routes.draw do
  devise_for :users
  root "admin/dashboard#index"
  get "landing_pages/show"
  get "/lp/:uuid", to: "landing_pages#show", as: :landing_page

  namespace :admin do
    get "dashboard/index"
    root "dashboard#index"
    resources :businesses do
      collection do
        post :import
      end
      resources :preview_links, only: [ :create, :destroy ]
    end
    get "templates/:id/preview", to: "templates#preview", as: :template_preview
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
