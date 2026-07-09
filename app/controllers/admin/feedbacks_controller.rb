class Admin::FeedbacksController < ApplicationController
  layout "admin"

  before_action :set_feedback, only: %i[show edit update destroy resolve close]
  before_action :ensure_feedback!, only: %i[show edit update destroy resolve close]
  before_action :authorize_view!, only: %i[show]
  before_action :authorize_edit!, only: %i[edit update]
  before_action :authorize_destroy!, only: %i[destroy]
  before_action :authorize_manage!, only: %i[resolve close]

  def index
    @stats = Admin::FeedbackStats.call
    @users = User.order(:name, :email)
    @pagy, @feedbacks = pagy(filtered_feedbacks.recent_first.includes(:user, screenshots_attachments: :blob), limit: 25)
  end

  def show
  end

  def new
    @feedback = Feedback.new(page_url: params[:page_url])
  end

  def create
    @feedback = FeedbackSubmissionService.new(
      user: current_user,
      attributes: submission_params,
      screenshots: screenshot_uploads
    ).call

    redirect_to admin_feedback_path(@feedback), notice: "Feedback submitted successfully."
  rescue ActiveRecord::RecordInvalid => e
    @feedback = e.record
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    FeedbackUpdateService.new(
      feedback: @feedback,
      attributes: update_attributes,
      screenshots: screenshot_uploads,
      remove_screenshot_ids: params.dig(:feedback, :remove_screenshot_ids)
    ).call

    redirect_to admin_feedback_path(@feedback), notice: "Feedback updated."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @feedback.destroy!
    redirect_to admin_feedbacks_path, notice: "Feedback deleted."
  end

  def resolve
    FeedbackUpdateService.new(
      feedback: @feedback,
      attributes: { status: "completed" }
    ).call

    redirect_to admin_feedback_path(@feedback), notice: "Feedback marked as completed."
  rescue ActiveRecord::RecordInvalid
    redirect_to admin_feedback_path(@feedback), alert: @feedback.errors.full_messages.to_sentence
  end

  def close
    FeedbackUpdateService.new(
      feedback: @feedback,
      attributes: { status: "closed" }
    ).call

    redirect_to admin_feedback_path(@feedback), notice: "Feedback closed."
  rescue ActiveRecord::RecordInvalid
    redirect_to admin_feedback_path(@feedback), alert: @feedback.errors.full_messages.to_sentence
  end

  private

  def scoped_feedbacks
    employee_role? ? Feedback.for_user(current_user) : Feedback.all
  end

  def filtered_feedbacks
    scope = scoped_feedbacks.includes(:user)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(feedback_type: params[:feedback_type]) if params[:feedback_type].present?
    scope = scope.where(priority: params[:priority]) if params[:priority].present?
    scope = scope.where(user_id: params[:user_id]) if filterable_user? && params[:user_id].present?

    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.left_outer_joins(:user).where(
        "feedbacks.title ILIKE :q OR feedbacks.description ILIKE :q OR users.email ILIKE :q OR users.name ILIKE :q",
        q: q
      )
    end

    scope
  end

  def set_feedback
    @feedback = Feedback.find_by(id: params[:id])
  end

  def ensure_feedback!
    return if @feedback.present?

    redirect_to admin_feedbacks_path, alert: "Feedback not found."
  end

  def authorize_view!
    return if super_admin? || admin_role?
    return if @feedback.user_id == current_user.id

    redirect_to admin_feedbacks_path, alert: "You do not have access to this feedback."
  end

  def authorize_edit!
    return if @feedback.editable_by?(current_user)

    redirect_to admin_feedback_path(@feedback), alert: "You cannot edit this feedback."
  end

  def authorize_destroy!
    return if @feedback.deletable_by?(current_user)

    redirect_to admin_feedbacks_path, alert: "You do not have permission to delete feedback."
  end

  def authorize_manage!
    return if super_admin?

    redirect_to admin_feedback_path(@feedback), alert: "Only super admins can perform this action."
  end

  def filterable_user?
    super_admin? || admin_role?
  end
  helper_method :filterable_user?

  def update_attributes
    attrs = if super_admin?
      feedback_params.to_h
    elsif admin_role?
      feedback_params.slice(:priority, :status, :admin_notes).to_h
    else
      submission_params.to_h
    end

    attrs
  end

  def submission_params
    params.require(:feedback).permit(
      :title,
      :description,
      :feedback_type,
      :browser,
      :operating_system,
      :page_url,
      :steps_to_reproduce,
      :expected_result,
      :actual_result,
      screenshots: []
    )
  end

  def feedback_params
    params.require(:feedback).permit(
      :title,
      :description,
      :feedback_type,
      :priority,
      :status,
      :browser,
      :operating_system,
      :page_url,
      :steps_to_reproduce,
      :expected_result,
      :actual_result,
      :admin_notes,
      screenshots: [],
      remove_screenshot_ids: []
    )
  end

  def screenshot_uploads
    Array(params.dig(:feedback, :screenshots)).compact_blank
  end
end
