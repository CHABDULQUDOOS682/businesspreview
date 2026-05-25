class HomePagesController < ApplicationController
    layout "home"

    skip_before_action :authenticate_user!

    def index
        @reviews = Review.where(active: true).order(created_at: :desc)
    end

    def services
    end

    def workflow
        render :process
    end

    def pricing
    end

    def portfolio
    end

    def contact
    end

    def privacy
    end
end
