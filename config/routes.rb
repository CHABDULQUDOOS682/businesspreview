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

  # TWILIO ROUTES
  # Create Voice Controller (TwiML)
  post "twilio/voice", to: "twilio#voice"
  # Receive Incoming SMS (Webhook)
  post "twilio/sms"


  get "up" => "rails/health#show", as: :rails_health_check

  # Routes for frontend
  get "design_1", to: "frontend#design_1", as: :design_1
  
end
