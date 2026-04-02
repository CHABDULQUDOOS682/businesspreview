class HomePagesController < ApplicationController
    layout "home"

    skip_before_action :authenticate_user!

    def index
    end

    def services
    end

    def workflow
        render :process
    end

    def contact
    end

    def privacy
    end
end
