class Admin::NotesController < ApplicationController
  layout "admin"

  before_action :set_note, only: [ :edit, :update, :destroy ]

  def index
    scope = Note.includes(:business, :user).order(created_at: :desc)

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

    @users = User.all.order(:name, :email)
    @pagy, @notes = pagy(scope, limit: 25)
    @total_count = Note.count
  end

  def create
    @note = Note.new(note_params)
    @note.user = current_user

    if @note.save
      redirect_back fallback_location: admin_business_path(@note.business), notice: "Note added."
    else
      redirect_back fallback_location: admin_business_path(@note.business), alert: @note.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
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

  def note_params
    params.require(:note).permit(:body, :business_id)
  end
end
