class LandingPagesController < ApplicationController
  skip_before_action :authenticate_user!
  layout "public"

  def show
    link = PreviewLink.find_by!(uuid: params[:uuid])
    @business = link.business

    link.increment!(:visit_count)
    @business.increment!(:visit_count)

    if link.clicked_at.nil?
      link.update(
        clicked_at: Time.current,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
    end

    render "templates/#{link.template}"
  end
end
