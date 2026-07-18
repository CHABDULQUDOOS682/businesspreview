# frozen_string_literal: true

module Admin
  class PwaController < ApplicationController
    skip_before_action :authenticate_user!, only: [ :manifest, :service_worker ]
    skip_before_action :set_unread_message_count, only: [ :manifest, :service_worker ]
    skip_forgery_protection only: [ :manifest, :service_worker ]
    before_action :require_super_admin!, only: [ :install_click ]
    layout false

    def manifest
      origin = request.base_url

      payload = {
        id: "#{origin}/admin",
        name: "DevDeBizz Admin",
        short_name: "DevDeBizz",
        description: "DevDeBizz admin portal",
        start_url: "#{origin}/admin",
        scope: "#{origin}/",
        display: "standalone",
        display_override: [ "standalone", "minimal-ui" ],
        orientation: "any",
        lang: "en",
        dir: "ltr",
        prefer_related_applications: false,
        theme_color: "#081849",
        background_color: "#081849",
        icons: [
          {
            src: "#{origin}/icon-192.png",
            sizes: "192x192",
            type: "image/png",
            purpose: "any"
          },
          {
            src: "#{origin}/icon-512.png",
            sizes: "512x512",
            type: "image/png",
            purpose: "any"
          },
          {
            src: "#{origin}/icon-512.png",
            sizes: "512x512",
            type: "image/png",
            purpose: "maskable"
          }
        ]
      }

      expires_in 5.minutes, public: false
      response.set_header("Content-Type", "application/manifest+json; charset=utf-8")
      render json: payload
    end

    def service_worker
      expires_now
      response.headers["Service-Worker-Allowed"] = "/"
      response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
      render plain: public_service_worker_js, content_type: "application/javascript; charset=utf-8"
    end

    def install_click
      Rails.logger.info(
        "[PWA] install_click user_id=#{current_user.id} " \
        "has_prompt=#{params[:has_prompt]} " \
        "sw=#{params[:service_worker]} " \
        "standalone=#{params[:standalone]} " \
        "ua=#{request.user_agent.to_s.truncate(160)}"
      )

      respond_to do |format|
        format.html { redirect_to admin_root_path }
        format.json {
          render json: {
            ok: true,
            has_prompt: ActiveModel::Type::Boolean.new.cast(params[:has_prompt]),
            manifest_url: admin_manifest_url
          }
        }
      end
    end

    private

    def public_service_worker_js
      path = Rails.root.join("public/service-worker.js")
      path.exist? ? path.read : fallback_service_worker_js
    end

    def fallback_service_worker_js
      <<~JS
        self.addEventListener("install", (event) => { event.waitUntil(self.skipWaiting()); });
        self.addEventListener("activate", (event) => { event.waitUntil(self.clients.claim()); });
        self.addEventListener("fetch", (event) => { event.respondWith(fetch(event.request)); });
      JS
    end
  end
end
