class Admin::UsersController < ApplicationController
  layout "admin"

  before_action :require_user_management_access!
  before_action :set_user, only: [ :toggle_status, :resend_invite, :destroy ]

  def index
    @users = manageable_users.order(created_at: :desc)
  end

  def new
    @user = User.new(role: allowed_roles.first)
  end

  def create
    @user = User.new(permitted_user_attributes)
    requested_role = params.dig(:user, :role)
    @user.role = allowed_roles.include?(requested_role) ? requested_role : allowed_roles.first
    temporary_password = SecureRandom.hex(12)
    @user.password = temporary_password
    @user.password_confirmation = temporary_password
    @user.active = false

    if @user.save
      @user.send_reset_password_instructions
      redirect_to admin_users_path, notice: "#{@user.role.humanize} account created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def toggle_status
    unless current_user.can_manage?(@user)
      redirect_to admin_users_path, alert: "You do not have permission to update that user."
      return
    end

    @user.update!(active: !@user.active?)
    redirect_to admin_users_path, notice: "#{@user.email} is now #{@user.active? ? 'active' : 'inactive'}."
  end

  def resend_invite
    unless current_user.can_manage?(@user)
      redirect_to admin_users_path, alert: "You do not have permission to update that user."
      return
    end

    unless @user.active?
      @user.send_reset_password_instructions
      redirect_to admin_users_path, notice: "A new invite email has been sent to #{@user.email}."
      return
    end

    redirect_to admin_users_path, alert: "Only inactive users can be reinvited."
  end

  def destroy
    unless current_user.can_manage?(@user)
      redirect_to admin_users_path, alert: "You do not have permission to delete that user."
      return
    end

    @user.destroy!
    redirect_to admin_users_path, notice: "#{@user.email} has been deleted."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def manageable_users
    return User.all if current_user.role_super_admin?
    return User.managed_by_admin if current_user.role_admin?

    User.none
  end

  def allowed_roles
    current_user.manageable_roles
  end

  def permitted_user_attributes
    params.require(:user).permit(:email)
  end
end
