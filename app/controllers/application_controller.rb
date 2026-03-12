class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  before_action :authenticate_user!
  before_action :set_unread_message_count, if: :user_signed_in?
  helper_method :unread_message_count
  allow_browser versions: :modern

  private

  def set_unread_message_count
    @unread_message_count = Message.inbound.unread.count
  end

  def unread_message_count
    @unread_message_count.to_i
  end
end
