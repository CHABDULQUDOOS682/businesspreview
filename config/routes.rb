Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ], controllers: { passwords: "users/passwords" }
  # root "admin/dashboard#index"
  root "home_pages#index"
  get "services", to: "home_pages#services"
  get "about", to: "home_pages#about"
  get "process", to: "home_pages#workflow"
  get "pricing", to: "home_pages#pricing"
  get "portfolio", to: "home_pages#portfolio"
  get "contact", to: "home_pages#contact"
  post "contact", to: "home_pages#create_contact", as: :contact_submissions
  get "privacy", to: "home_pages#privacy"
  get "careers", to: "home_pages#careers"
  get "press", to: "home_pages#press"
  get "partners", to: "home_pages#partners"
  get "blog", to: "home_pages#blog"
  get "help_center", to: "home_pages#help_center"
  get "documentation", to: "home_pages#documentation"
  get "brand_kit", to: "home_pages#brand_kit"
  get "terms", to: "home_pages#terms"
  get "cookie_policy", to: "home_pages#cookie_policy"
  get "gdpr", to: "home_pages#gdpr"
  get "accessibility", to: "home_pages#accessibility"

  get "landing_pages/show"
  get "/lp/:uuid", to: "landing_pages#show", as: :landing_page
  get "/pay/:token", to: "payment_invoice_links#show", as: :payment_invoice_link
  get "/reviews/new/:token", to: "reviews#new", as: :new_review_submission
  post "/reviews", to: "reviews#create", as: :review_submissions

  namespace :admin do
    get "dashboard/index"
    root "dashboard#index"
    resources :tasks, only: [ :index, :update ]
    resources :call_logs, only: [ :index ]
    resources :payment_invoices, only: [ :index ]
    resources :preview_links, only: [ :index, :create, :destroy ]
    resources :users, only: [ :index, :new, :create, :destroy ] do
      member do
        patch :toggle_status
        post :resend_invite
      end
    end
    resources :notes, only: [ :index, :create, :edit, :update, :destroy ]
    resources :businesses do
      collection do
        post :import
      end
      resources :payment_invoices, only: [ :create ]
      member do
        post :send_review_link
      end
    end
    resources :communications, only: [ :index, :show, :create ] do
      collection do
        post :bulk_create
      end
      member do
        post :call
      end
    end
    resources :reviews do
      member do
        patch :toggle_active
      end
    end
    resources :commission_rates, only: [ :index, :update ]
    get "templates/:id/preview", to: "templates#preview", as: :template_preview
  end

  # TWILIO ROUTES
  # Create Voice Controller (TwiML)
  post "twilio/voice", to: "twilio#voice"
  # Receive Incoming SMS (Webhook)
  post "twilio/sms", to: "twilio#sms"

  # Browser-to-phone calling
  get "twilio/token", to: "twilio#access_token"
  post "twilio/connect", to: "twilio#connect_call"

  post "webhooks/stripe", to: "stripe_webhooks#create"


  get "up" => "rails/health#show", as: :rails_health_check

  # Routes for frontend
  get "design_1", to: "frontend#design_1", as: :design_1
  get "abc", to: "frontend#abc", as: :abc
end
