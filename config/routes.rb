Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ], controllers: { passwords: "users/passwords" }
  # root "admin/dashboard#index"
  root "home_pages#index"

  get "robots.txt", to: "seo#robots", as: :robots
  get "sitemap.xml", to: "seo#sitemap", as: :sitemap, defaults: { format: :xml }

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
  get "blog/:slug", to: "home_pages#blog_show", as: :blog_post
  get "help_center", to: "home_pages#help_center"
  get "documentation", to: "home_pages#documentation"
  get "brand_kit", to: "home_pages#brand_kit"
  get "terms", to: "home_pages#terms"
  get "cookie_policy", to: "home_pages#cookie_policy"
  get "gdpr", to: "home_pages#gdpr"
  get "accessibility", to: "home_pages#accessibility"

  get "schedule", to: "scheduling#new", as: :schedule
  get "schedule/slots", to: "scheduling#slots", as: :schedule_slots
  post "schedule", to: "scheduling#create", as: :schedule_bookings
  get "schedule/confirmation/:token", to: "scheduling#confirmation", as: :schedule_confirmation

  get "landing_pages/show"
  get "/lp/:uuid", to: "landing_pages#show", as: :landing_page
  get "/pay/:token", to: "payment_invoice_links#show", as: :payment_invoice_link
  get "/reviews/new/:token", to: "reviews#new", as: :new_review_submission
  post "/reviews", to: "reviews#create", as: :review_submissions

  # Root-scoped PWA worker (required for Chrome/Oppo installability).
  get "service-worker.js", to: "admin/pwa#service_worker", as: :service_worker

  namespace :admin do
    get "dashboard/index"
    root "dashboard#index"
    get "manifest.webmanifest", to: "pwa#manifest", as: :manifest
    get "service-worker.js", to: "pwa#service_worker", as: :legacy_service_worker
    post "pwa/install_click", to: "pwa#install_click", as: :pwa_install_click
    resources :tasks, only: [ :index ]
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
    resources :cold_calling_scripts
    resources :meetings, except: [ :show, :destroy ] do
      collection do
        get :slots
      end
      member do
        patch :cancel
      end
    end
    resource :availability_rules, only: [ :edit, :update ]
    resources :feedbacks do
      member do
        patch :resolve
        patch :close
      end
    end
    resources :businesses do
      collection do
        post :import
      end
      resources :payment_invoices, only: [ :create ]
      member do
        post :send_review_link
        post :verify_phone
      end
    end
    resources :business_imports, only: [ :index, :show ] do
      member do
        get :download, defaults: { format: "csv" }
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
    resources :blog_posts do
      member do
        patch :toggle_active
      end
    end
    resources :portfolio_items do
      member do
        patch :toggle_active
      end
    end
    resources :commissions, only: [ :index ] do
      member do
        patch :approve
        patch :mark_paid_out
      end
    end
    resources :commission_rates, only: [ :index, :update ]
    resources :jobs, only: [ :index, :show ] do
      member do
        post :retry
      end
    end
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
  post "twilio/dial_status", to: "twilio#dial_status"

  post "webhooks/stripe", to: "stripe_webhooks#create"
  post "webhooks/google_calendar", to: "google_calendar_webhooks#create"
  post "webhooks/content_updates", to: "content_update_webhooks#create"
  post "webhooks/sitepilot/connection_status", to: "sitepilot_connection_status#create"


  get "up" => "rails/health#show", as: :rails_health_check

  # Routes for frontend
  get "design_1", to: "frontend#design_1", as: :design_1
  get "abc", to: "frontend#abc", as: :abc
end
