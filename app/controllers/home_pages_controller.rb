class HomePagesController < ApplicationController
    layout "home"

    skip_before_action :authenticate_user!

    def index
        @reviews = Review.where(active: true).order(created_at: :desc)
    end

    def services
    end

    def about
    end

    def workflow
        render :process
    end

    def pricing
    end

    def portfolio
        @portfolio_items = PortfolioItem.published
        @portfolio_categories = [ "All" ] + @portfolio_items.map(&:category).uniq
    end

    def contact
    end

    # POST /contact
    def create_contact
        # 1. Safely whitelist incoming form fields using strong parameters
        contact_params = params.permit(:first_name, :last_name, :email, :company, :service_interest, :message)

        # 2. Hand off the layout variables directly to your background mailer thread
        ContactMailer.new_lead_alert(contact_params).deliver_later

        # 3. Bounce them right back to the contact screen with a success notice
        redirect_to contact_path, notice: "Thank you! Your inquiry was sent successfully. We'll be in touch within one business day."
    end

    def privacy
    end

    def careers
    end

    def press
    end

    def partners
    end

    def blog
        @blog_posts = BlogPost.published
    end

    def blog_show
        @blog_post = BlogPost.published.find_by!(slug: params[:slug])
        raise ActiveRecord::RecordNotFound unless @blog_post.readable?
    end

    def help_center
    end

    def documentation
    end

    def brand_kit
    end

    def terms
    end

    def cookie_policy
    end

    def gdpr
    end

    def accessibility
    end
end
