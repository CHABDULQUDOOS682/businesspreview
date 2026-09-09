class Admin::NotesController < ApplicationController
  layout "admin"

  before_action :set_note, only: [ :edit, :update, :destroy ]
  before_action :authorize_note_access!, only: [ :edit, :update, :destroy ]

  def index
    scope = accessible_notes.includes(:business, :user).order(created_at: :desc)

    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.joins(:business).left_outer_joins(:user)
                   .where("notes.body ILIKE :q OR businesses.name ILIKE :q OR users.email ILIKE :q OR users.name ILIKE :q", q: q)
    end

    if params[:role].present?
      scope = scope.joins(:user).where(users: { role: params[:role] })
    end

    if params[:user_id].present?
      scope = scope.where(user_id: params[:user_id])
    end

    @users = employee_role? ? User.where(id: current_user.id) : User.all.order(:name, :email)
    @pagy, @notes = pagy(scope, limit: 25)
    @total_count = accessible_notes.count
  end

  def create
    @note = Note.new(note_params)
    @note.user = current_user

    unless note_business_accessible?(@note.business_id)
      redirect_back fallback_location: admin_notes_path,
                    alert: "You do not have access to that business."
      return
    end

    if @note.save
      redirect_back fallback_location: admin_business_path(@note.business), notice: "Note added."
    else
      redirect_back fallback_location: admin_business_path(@note.business), alert: @note.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    unless note_business_accessible?(note_params.fetch(:business_id, @note.business_id))
      redirect_to admin_notes_path, alert: "You do not have access to that business."
      return
    end

    if @note.update(note_params)
      redirect_to admin_business_path(@note.business), notice: "Note updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    business = @note.business
    @note.destroy
    redirect_back fallback_location: admin_business_path(business), notice: "Note deleted."
  end

  private

  def set_note
    @note = Note.find(params[:id])
  end

  # Employees work a subset of the pipeline, so their notes view is limited to
  # the businesses assigned to them.
  def accessible_notes
    return Note.all unless employee_role?

    Note.where(business_id: Business.assigned_to_user(current_user).select(:id))
  end

  def note_business_accessible?(business_id)
    return true unless employee_role?

    Business.assigned_to_user(current_user).exists?(id: business_id)
  end

  # An employee may only touch their own notes, and only on their businesses.
  def authorize_note_access!
    return unless employee_role?
    return if @note.user_id == current_user.id && note_business_accessible?(@note.business_id)

    redirect_to admin_notes_path, alert: "You do not have access to that note."
  end

  def note_params
    params.require(:note).permit(:body, :business_id)
  end
end
