# Pin npm packages by running ./bin/importmap

pin "application"
pin "pwa_bootstrap"
pin "call/twilio_call_manager", to: "call/twilio_call_manager.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "swiper", to: "https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.mjs"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
